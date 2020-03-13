//
//  Favorite.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/13/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Favorite {
    let itemName: String
    let favoritedDate: Timestamp
    let imageURL: String
    let itemId: String
    let price: Double
    let sellerId: String
    let sellerName: String
    
}
extension Favorite {
    // failable initializer( question mark means failable). COMPARE TO ITEM MODEL
    // all properties need to exist oin order for ob ject to get created
    init?(_ dictionary: [String: Any]) {
        
       guard let itemName = dictionary["itemName"] as? String,
        let favoritedDate = dictionary["favoritedDate"] as? Timestamp,
        let imageURL = dictionary["imageURL"] as? String,
        let itemId = dictionary["itemId"] as? String,
        let price = dictionary["price"] as? Double,
        let sellerId = dictionary["sellerId"] as? String,
        let sellerName = dictionary["sellerName"] as? String else {
            
            return nil
        }
        self.itemName = itemName
        self.favoritedDate = favoritedDate
        self.imageURL = imageURL
        self.itemId = itemId
        self.price = price
        self.sellerId = sellerId
        self.sellerName = sellerName
        
        
    }
}
