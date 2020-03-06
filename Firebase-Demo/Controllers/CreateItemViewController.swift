//
//  CreateItemViewController.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateItemViewController: UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    
    
    @IBOutlet weak var itemPriceTextField: UITextField!
    
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    private var category: Category
    
    private let dbService = DatabaseService()
    private var storageService = StorageService()
    
    private  lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    private var selectedImage: UIImage? {
        didSet {
            itemImageView.image = selectedImage
        }
    }
    
    private lazy var lingPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer()
        gesture.addTarget(self, action: #selector(showPhotoOptions))
        return gesture
    }()
    
    init?(coder: NSCoder, category: Category) {
        self.category = category
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = category.name
        
        // add long press gesture to itemImageView
        itemImageView.isUserInteractionEnabled = true
        itemImageView.addGestureRecognizer(lingPressGesture)
       
    }
    
    @objc private func showPhotoOptions() {
        let alertController = UIAlertController(title: "Choose Photo Option", message: nil, preferredStyle: .actionSheet)
        let camerAction = UIAlertAction(title: "Camera", style: .default) { alertAction in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true)
        }
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        if UIImagePickerController.isSourceTypeAvailable(.camera){
        alertController.addAction(camerAction)
        }
        
        alertController.addAction(photoLibrary)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func postItemButtonPressed(_ sender: UIBarButtonItem) {
        guard let itemName = itemNameTextField.text,
            !itemName.isEmpty,
            let priceText = itemPriceTextField.text,
            !priceText.isEmpty,
            let price = Double(priceText),
            let selectedImage = selectedImage else {
                showAlert(title: "Missing Fields", message: "All fields are required")
                return
        }
        guard let displayName = Auth.auth().currentUser?.displayName else {
            showAlert(title: "Incomplete profile", message: "Please complete your Profile")
            return
        }
        // resize image before uploadimg to storage
        let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: itemImageView.bounds)
        
        dbService.createItem(itemName: itemName, price: price, category: category, displayName: displayName) {[weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error creating Item", message: "Sorry something went wrong: \(error.localizedDescription)")
                }
            case .success(let documentId):
                // upload photo to storage
                self?.uploadPhoto(photo: resizedImage, documentId: documentId)
//                DispatchQueue.main.async {
//                    self?.showAlert(title: nil, message: "Successfully listed your item")
//                }
            }
        }
        
        // dismisses view
       // dismiss(animated: true)
    }
    private func uploadPhoto(photo: UIImage, documentId: String) {
        storageService.uploadPhoto( itemId: documentId, image: photo) { [weak self](result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "error uploading photo", message: "\(error.localizedDescription)")
                }
            case .success(let url):
                self?.updateItemImageURL(url, documentId: documentId)
            }
        }
    }
    private func updateItemImageURL( _ url: URL, documentId: String) {
        // update unexisting doc on Firebase
        Firestore.firestore().collection(DatabaseService.itemsCollection).document(documentId).updateData(["imageURL" : url.absoluteString]) {[weak self] (error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Failed to update item", message: "\(error.localizedDescription)")
                }
            } else {
                print("all went well with update")
                DispatchQueue.main.async {
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    

}
extension CreateItemViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("could not attain original image")
        }
        selectedImage = image
        dismiss(animated: true)
    }
}
