//
//  CollectionViewUser.swift
//  Split
//
//  Created by Timothy Chodins on 8/22/16.
//  Copyright © 2016 Tarun Khasnavis. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import FirebaseStorage

let notificationKey = "USERADDED"
let defaultPh = #imageLiteral(resourceName: "defaultPhoto")
var usersLoaded: Bool = false

struct userState {
    
    static var users: [CollectionViewUser] = [CollectionViewUser]()
    
    //Itd be a shame if a user got added twice
    static var noRepeats: [String : Bool] = [String: Bool]()
}

func userForId(id: String) -> CollectionViewUser? {
    for user in userState.users {
        if user.getUid() == id {
            return user
        }
    }
    return nil
}

struct curUser {
    
    static var email: String = ""
    static var name: String = ""
    static var id: String = ""
    static var image: UIImage = UIImage()
    static var gid: String = ""
    static var groupName: String = ""
    
}

extension UIImage {
    var rounded: UIImage? {
        let imageView = UIImageView(image: self)
        imageView.layer.cornerRadius = min(size.height/4, size.width/4)
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}


class CollectionViewUser: Hashable {
    
    var name: String
    var uid: String
    var image: UIImage
    
    init?(name: String, uid: String, image: UIImage) {
        self.name = name
        self.uid = uid
        self.image = image.circle!
    }
    
    func getName() -> String {
        return self.name
    }
    
    func getUid() -> String {
        return self.uid
    }
    
    func getImage() -> UIImage {
        return self.image
    }
    
    public static func ==(lhs: CollectionViewUser, rhs: CollectionViewUser) -> Bool {
        return lhs.getUid() == rhs.getUid()
    }
    
    public var hashValue: Int {
        return uid.hashValue
    }
    
    
}


typealias CompletionHandler = (_ success: Bool) -> Void

func loadCurUser(_ completionHandler: @escaping CompletionHandler) {
    let uid = FIRAuth.auth()?.currentUser?.uid
    let ref = FIRDatabase.database().reference()
    let storageRef = FIRStorage.storage().reference(forURL: "gs://chores-17bf7.appspot.com")
    var topic = "user_"+uid!
    
    FIRMessaging.messaging().subscribe(toTopic: topic)
    ref.child("User").child(uid!).observeSingleEvent(of: .value, with: {
        (snapshot) -> Void in
        let value = snapshot.value as! NSDictionary
        
        curUser.email = value["email"] as! String
        curUser.name = value["name"] as! String
        curUser.id = uid!
        
        storageRef.child("images").child(uid!).data(withMaxSize: 50*1024*1024, completion: {(data1, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
                curUser.image = defaultPh
            } else {
                print("Success")
                curUser.image = UIImage(data: data1!)!
            }
            print("Completed loading curUser")
            completionHandler(true)
        })
        
        
    })
    
    
}


func obtainInfo(id: String, completionHandler: @escaping CompletionHandler) {
    let ref = FIRDatabase.database().reference()
    let userRef = ref.child("User")
    let storageRef = FIRStorage.storage().reference(forURL: "gs://chores-17bf7.appspot.com")
    
    print("JERE")
    
    userRef.child(id).observeSingleEvent(of: .value, with: {(userSnapshot) -> Void in
        let value = userSnapshot.value as! NSDictionary
        let name = value["name"] as! String
        print("loading: " + name)
        
        storageRef.child("images").child(id).data(withMaxSize: 50*1024*1024, completion: {(data1, error) -> Void in
            if let error = error {
                userState.users.append(CollectionViewUser.init(name: name, uid: id, image: #imageLiteral(resourceName: "defaultPhoto"))!)
            } else {
                print("Succevvvss")
                userState.users.append(CollectionViewUser.init(name: name, uid: id, image: UIImage(data: data1!)!)!)
                
            }
            print(userState.users.count)
            completionHandler(true)
        })
        
    })
    
    
}


//LOADING SPINNER, we need one for this
func loadUsers(_ completetionHandler: @escaping CompletionHandler) {
    print("loading users")
    
    let uid = FIRAuth.auth()?.currentUser?.uid
    userState.noRepeats = [String: Bool]()
    userState.users = [CollectionViewUser]()
    
    //Load current user
    loadCurUser() { (success) in
        let ref = FIRDatabase.database().reference()
        
        //Attempt to load other users in group
        ref.child("User").child(uid!).child("group").observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            print("uid: " + uid!)
            let groupid = snapshot.value as! String
            print("groupid: " + groupid)
            curUser.gid = groupid
            
            //add listener for users
            let membersRef = FIRDatabase.database().reference().child("Group").child(groupid)
            
            
            membersRef.observeSingleEvent(of: .value, with: {(memberSnapshot) -> Void in
                print("actually loading")
                //dictionary of members
                let groupDict = memberSnapshot.value as! [String : Any]
                passcode = groupDict["passcode"] as! String
                curUser.groupName = groupDict["name"] as! String
                let membersDict = groupDict["members"] as! [String : Bool]
                let totalMembers = membersDict.count
                
                
                //Iterate through all members id and collect information
                var mygroup = DispatchGroup.init()
                let queue = DispatchQueue.init(label: "com.edmundthomas", attributes: .concurrent, target: .main)
                
                for (id, d) in membersDict {
                    print(id)
                    
                    if id == curUser.id {
                        if (userState.noRepeats.updateValue(true, forKey: id) == nil) {
                            userState.users.append(CollectionViewUser.init(name: curUser.name, uid: id, image: curUser.image)!)
                            
                        }
                        
                    }
                    else {
                        queue.async(group: mygroup) {
                            
                            if (userState.noRepeats.updateValue(true, forKey: id) == nil) {
                                print("Do we make it here")
                                obtainInfo(id: id) { (success) in}
                            }
                            
                        }
                        
                    }
                }
                
                mygroup.notify(queue: queue) {
                    usersLoaded = true
                    completetionHandler(true)
                }
            })
        })
    }
    
}


