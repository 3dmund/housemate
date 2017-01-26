//
//  User.swift
//  Split
//
//  Created by Timothy Chodins on 8/6/16.
//  Copyright © 2016 Tarun Khasnavis. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class User {
    //MARK: Properties
    var name: String
    var picture: NSData
    var snapshot: FIRDataSnapshot?
    var facebook: Bool = false
    var email: String
    var uid: String = ""
    
    init?(name: String, email: String, picture: NSData, facebook: Bool, uid: String) {
        self.name = name
        self.picture = picture
        self.email = email
        self.facebook = facebook
        self.uid = uid
    }
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    func addUser( _ completetionHandler: @escaping CompletionHandler) {
        print("adding user")
        print(self.uid)
        
        var user : [String : AnyObject] = ["name" : name as AnyObject, "email" : email as AnyObject, "facebook": facebook as AnyObject]
        let databaseRef = FIRDatabase.database().reference()
        let newData : FIRDatabaseReference
        newData = databaseRef.child("User").child(self.uid)
        /*
         if user["facebook"] as! Bool {
         newData = databaseRef.child("User").child(self.uid)
         
         } else {
         newData = databaseRef.child("User").childByAutoId()
         let id = newData.key
         self.uid = id
         }
         */
        user["group"] = "" as AnyObject
        let userAsNSDict = user as NSDictionary
        newData.setValue(userAsNSDict)
        
        let storageRef = FIRStorage.storage().reference(forURL: "gs://chores-17bf7.appspot.com")
        storageRef.child("images").child(self.uid).put(self.picture as Data, metadata: nil) { (metadata, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print(metadata?.downloadURL()?.absoluteString as Any)
                completetionHandler(true)
            }
            
            
        }
    }
    
}
