//
//  DatabaseService.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class DatabaseService {
    
    static let itemsCollection = "items"
    
    static let usersCollection = "users"
    
    static let commentsCollection = "comments"//sub collection on an item document
    
    static let favoritesCollection = "favorites" // sub collection on a user document
    // review - firebase works like this, firestore hieraerchy
    // top level
    // collection -> document -> collection-> document -> ...
    
    // lets get a reference to the firebase firestore database
    private let db = Firestore.firestore()
    
    public func createItem(itemName: String, price: Double, category: Category, displayName: String, completion: @escaping (Result <String,Error>) ->()){
         
        guard let user = Auth.auth().currentUser else { return }
        
        // generate a document for the "items" collection (could be any piece od data like product, like, photo...)
        let documentRef = db.collection(DatabaseService.itemsCollection).document()
        
        // create document in our items collection
        // data we pass has to be key:value format
        db.collection(DatabaseService.itemsCollection).document(documentRef.documentID).setData(["itemName":itemName, "price": price, "itemId":documentRef.documentID, "listedDate":Timestamp(date: Date()), "sellerName":displayName,"sellerId":user.uid, "categoryName":category.name]) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(documentRef.documentID))
            }
        }
    }
    
    public func createDatbaseUser(authDataResult: AuthDataResult, completion: @escaping (Result<Bool, Error>) -> ()) {
        
        guard let email = authDataResult.user.email else {
            return
        }
     
        // add any other parameters ypu need to this dictionary( like displayNAme)
db.collection(DatabaseService.usersCollection).document(authDataResult.user.uid).setData(["email" : email, "createdDate": Timestamp(date: Date()), "userId": authDataResult.user.uid]) { (error) in
    if let error = error {
        completion(.failure(error))
    } else {
        completion(.success(true))
    }
        }
    }
    
    func updateDatabaseUser(displayName: String, photoURL: String, completiion: @escaping (Result<Bool, Error>) -> ()) {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        db.collection(DatabaseService.usersCollection).document(user.uid).updateData(["photoURL" : photoURL, "displayName": displayName]) { (error) in
            if let error = error {
                completiion(.failure(error))
            } else {
                completiion(.success(true))
            }
        }
    }
    
    public func deleteItem(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        db.collection(DatabaseService.itemsCollection).document(item.itemId).delete { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func postComment(item: Item, comment: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser,
            let displayName = user.displayName
        else {
            print("missing user data")
            
            return
            
        }
        let docRef = db.collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).document()
        
       // usinfg document from above to write its contents to firebase
        db.collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).document(docRef.documentID).setData(["text" : comment, "commentDate" : Timestamp(date: Date()), "itemName" : item.itemName, "itemId" : item.itemId, "sellerName": item.sellerName, "sellerId" : item.sellerId, "commentedBy": displayName]) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func addToFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        
       
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).setData(["itemName" : item.itemName, "price" : item.price, "imageURL" : item.imageURL, "favoritedDate" : Timestamp(date: Date()), "itemId" : item.itemId, "sellerName": item.sellerName, "sellerId": item.sellerId]) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func removeFromFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).delete { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func isItemInFAvorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        
        // in firebase we use "where" keyword to query (search) the collection
        
        // addSnapshotListener - continues to listen for modifications to collection
        // getDocuments - fetches documents ONLY once
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).whereField("itemId", isEqualTo: item.itemId).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let count = snapshot.documents.count // check if we have documents in favorites
                if count > 0 {
                    completion(.success(true))
                } else {
                    completion(.success(false))
                }
            }
        }
    }
    
    public func fetchUserItems(userId: String, completion: @escaping (Result<[Item], Error>) -> ()) {
        db.collection(DatabaseService.itemsCollection).whereField("sellerId", isEqualTo: userId).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let items = snapshot.documents.map { Item($0.data())} // returns items array
                completion(.success(items))
            }
        }
    }
    
    public func fetchFavorites(completion: @escaping (Result<[Favorite], Error>) -> ()) {
        // access users collection, go to user id (document) -> favorites
         guard let user = Auth.auth().currentUser else { return }
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let snapshot = snapshot {
                    // using compact map because initalizer for Favorite is failable(meaning no optionals)
                    // compactMap removes nil values from array. .map does not get rid of nil. Faleble initializer will return Favorite as a nil, if ony of the parameters is missing
                    let favorites = snapshot.documents.compactMap {Favorite($0.data())}
                    completion(.success(favorites))
                }
            }
        }
    }
}
