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

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    @IBOutlet weak var displayNameTextField: UITextField!
    
    
    
    @IBOutlet weak var emailLabel: UILabel!
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayNameTextField.delegate = self
        
        updateUI()
        
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
