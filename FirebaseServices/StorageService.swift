//
//  StorageService.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/4/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseStorage



class StorageService {
    
    // in our app we will  be uploading  a photo to Storage in 2 places: ProfileVC and CreateItemVC
    // we will eb creating 2 differeny=t buckets of folders: UserProfilePhotos/user.uid and ItemPhotos/itemId
    
    // lets create a reference to the firebase storage
    private let storageRef = Storage.storage().reference()
    // default parameters in Swift:userId: String? = nil(doesnt have to take in the parameter
    public func uploadPhoto(userId: String? = nil, itemId: String? = nil, image: UIImage, completion: @escaping (Result<URL, Error>) -> ()) {
        // 1. convert uiImage to data because this is the data objecy= we are posting to firebase
        guard let iamgeData = image.jpegData(compressionQuality: 1.0) else  {
            return
        }
        
        // we need to establish which bucket we will be saving to
        var photoReference: StorageReference!
        
        if let userId = userId { // coming from ProfileVC
            photoReference = storageRef.child("UserProfilrPhotos/\(userId).jpg")
        } else if let itemId = itemId{ // coming from CreateItemVC
            photoReference = storageRef.child("ItemsPhotos/\(itemId).jpg")
        }
        // configure metadata for the objrct being uploaded
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        let _ = photoReference.putData(iamgeData, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
            } else if let _ = metadata {
                photoReference.downloadURL { (url, error) in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url))
                    }
                }
            }
        }
        
        
        
        
        
        
        
        
        
    }
}
