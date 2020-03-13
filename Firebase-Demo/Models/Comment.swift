//
//  Comment.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Comment  {
    let commentDate: Timestamp
    let commentedBy: String
    let itemId: String
    let itemName: String
    let sellerName: String
    let text: String
    
}

extension Comment {
    init(_ dictionary: [String: Any]) {
        self.commentDate = dictionary["commentDate"] as? Timestamp ?? Timestamp(date: Date())
        self.commentedBy = dictionary["commentedBy"] as? String ?? "no commentedby"
        self.itemId = dictionary["itemId"] as? String ?? "no id"
        self.itemName = dictionary["itemName"] as? String ?? "no name"
        self.sellerName = dictionary["sellerName"] as? String ?? "mo name"
        self.text = dictionary["text"] as? String ?? "no text"
    }
}
