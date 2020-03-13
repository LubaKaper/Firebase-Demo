//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import Kingfisher

enum ViewState {
    case myItems
    case favorites
}

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    @IBOutlet weak var displayNameTextField: UITextField!
    
    
    
    @IBOutlet weak var emailLabel: UILabel!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    // setting up access to camera to make photos
    private lazy var imagePickerController: UIImagePickerController = {
        let ip = UIImagePickerController()
        ip.delegate = self
        return ip
    }()
    
    private var selectedImage: UIImage? {
        didSet {
            profileImageView.image = selectedImage
        }
    }
    
    private let storageService = StorageService()
    private let databaseService = DatabaseService()
    
    // from enum on top, when user clicks on segmented control, state changes
    private var viewState: ViewState = .myItems {
        didSet{
            // need to reload tableView every time state changes
            tableView.reloadData()
        }
    }
    
    // favorites data
    private var favorites = [Favorite]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // myitems data
    private var myItems = [Item]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private var refreshControll: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayNameTextField.delegate = self
        tableView.dataSource = self
        tableView.delegate = self 
        loadData()
        updateUI()
         tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
        
        // can do refresh controll or listener to update tableview when something is added to it
        refreshControll = UIRefreshControl()
        tableView.refreshControl = refreshControll
        refreshControll.addTarget(self, action: #selector(loadData), for: .valueChanged)
    }
    
   @objc private func loadData() {
        fetchItems()
        fetchFavorites()
    }
    
   @objc private func fetchItems() {
        guard let user = Auth.auth().currentUser else {
            refreshControll.endRefreshing()
            return
            
    }
        databaseService.fetchUserItems(userId: user.uid) { [weak self](result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Fetching error", message: error.localizedDescription)
                }
            case .success(let items):
                self?.myItems = items
            }
            DispatchQueue.main.async {
                self?.refreshControll.endRefreshing()
            }
        }
    }
    
    private func fetchFavorites() {
        databaseService.fetchFavorites { [weak self](result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "FAiled Fetching Favorites", message: error.localizedDescription)
                }
            case .success(let favorites):
                self?.favorites = favorites
                
            }
            DispatchQueue.main.async {
                self?.refreshControll.endRefreshing()
            }
        }
    }
    
    private func updateUI() {
        guard let user = Auth.auth().currentUser else {
                    return
                }
                emailLabel.text = user.email
                displayNameTextField.text = user.displayName
        profileImageView.kf.setImage(with: user.photoURL)
        //        user.displayName
        //        user.email
        //        user.phoneNumber
        //        user.photoURL

    }
    

    @IBAction func updateProfileButtonPressed(_ sender: UIButton) {
        // change the user's display name
        // make request
        // guard against empty
        guard let displayName = displayNameTextField.text,
            !displayName.isEmpty,
        let selectedImage = selectedImage else {
                print("missing fields")
                return
        }
        
        guard let user = Auth.auth().currentUser else { return }
        // resize image befor euploading to Firebse
        let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: profileImageView.bounds)
        
        print("original image size: \(selectedImage.size), resized image size: \(resizedImage.size)")
        
        // call storageService.upload
        storageService.uploadPhoto(userId: user.uid, image: resizedImage) { [weak self](result) in
            // code here to add the photoURL to user's photoURL property
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "error uploading photo", message: "\(error.localizedDescription)")
                }
            case .success(let url):
                self?.updateDatabaseUser(displayName: displayName, photoURL: url.absoluteString)
                //tODO: refactor into its own function
                let request = Auth.auth().currentUser?.createProfileChangeRequest()
                
                request?.displayName = displayName
                request?.photoURL = url
                request?.commitChanges(completion: { [unowned self] (error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Profile update", message: "error changing profile \(error.localizedDescription)")
                            print("commitChanges error: \(error)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Profile update", message: "Profile successfully updated")
                            print("profile successfully updated")
                        }
                    }
                })
            }
        }
        
    }
    
    private func updateDatabaseUser(displayName: String, photoURL: String) {
        databaseService.updateDatabaseUser(displayName: displayName, photoURL: photoURL) { [weak self] (result) in
            switch result {
            case .failure(let error):
               print("\(error)")
            case .success:
                print("succes updating user")
            }
        }
    }
    
    @IBAction func editProfileButtonPressed(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Choose Photo Action", message: nil, preferredStyle: .actionSheet)
        let camerAction = UIAlertAction(title: "Camera", style: .default){ alerAction in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default){ alerAction in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        if UIImagePickerController.isSourceTypeAvailable(.camera){
        alertController.addAction(camerAction)
        }
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    // could throw an error
    @IBAction func singoutButtonPressed(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UIViewController.showViewCintroller(storyboardName: "LoginView", viewControllerID: "LoginViewController")
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "error signing out", message: "\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func segmentedControlPressed(_ sender: UISegmentedControl) {
        // toggling current tableview state value
        switch sender.selectedSegmentIndex {
        case 0:
            viewState = .myItems
        case 1:
            viewState = .favorites
        default:
            break
        }
    }
    
    
}

extension ProfileViewController: UITextFieldDelegate {
    
    // dismisses keyboard after Enter pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
}
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
          return
        }
        selectedImage = image
        dismiss(animated: true)
    }
}
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewState == .myItems {
            return myItems.count
        } else {
            return favorites.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
            fatalError("Could not downcast to Itemcell")
        }
        if viewState == .myItems {
            let myItem = myItems[indexPath.row]
            cell.configureCell(fir: myItem)
        } else {
            let faveItem = favorites[indexPath.row]
            cell.confifureCell(for: faveItem)
        }
        return cell
    }
    
    
}

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
