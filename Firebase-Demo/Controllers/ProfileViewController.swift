//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    @IBOutlet weak var displayNameTextField: UITextField!
    
    
    @IBOutlet weak var emailLabel: UILabel!
    
    
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
            !displayName.isEmpty else {
                print("missing fields")
                return
        }
        let request = Auth.auth().currentUser?.createProfileChangeRequest()
        request?.displayName = displayName
        request?.commitChanges(completion: { (error) in
            if let error = error {
                self.showAlert(title: "Profile update", message: "error changing profile \(error)")
                print("commitChanges error: \(error)")
            } else {
                self.showAlert(title: "Profile update", message: "Profile successfully updated")
                print("profile successfully updated")
            }
        })
    }
    

}

extension ProfileViewController: UITextFieldDelegate {
    
    // dismisses keyboard after Enter pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
}
