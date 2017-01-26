//
//  Chore.swift
//  Chores
//
//  Created by Edmund Tian on 12/20/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class Chore: Hashable {
    
    // MARK: Properties
    var name: String
    var id: String
    var active: Bool
    var assigned: [String]
    var current: Int
    var timeActivated: String
    
    // Properties not set on initialization
    var currentlyAssigned: String
    var currentProPic: UIImage
    
    
    
    // MARK: Initialization
    
    init?(name: String, id: String, active: Bool, assigned: [String], current: Int, timeActivated: String) {
        self.name = name
        self.id = id
        self.active = active
        self.assigned = assigned
        self.current = current
        self.timeActivated = timeActivated
        if (name.isEmpty) {
            return nil
        }
        self.currentlyAssigned = ""
        self.currentProPic = UIImage()
        
    }
    
    func setCurrentlyAssigned(_ completetionHandler: @escaping CompletionHandler) {
        let currentUser = FIRAuth.auth()?.currentUser
        let currentId = self.assigned[self.current]
        let databaseRef = FIRDatabase.database().reference()
        let userRef = databaseRef.child("User").child(currentId)
        let userId = currentUser?.uid
        userRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            let value = snapshot.value as! NSDictionary
            let name = value["name"] as! String
            if userRef.key == userId {
                self.currentlyAssigned = "You"
            } else {
                self.currentlyAssigned = name
            }
            let collectionUser = userForId(id: userRef.key)
            self.currentProPic = collectionUser!.getImage()
            completetionHandler(true)
        })
    }
    
    func saveChore() {
        print("saving: " + self.name)
        var chore : [String : AnyObject] = ["name" : name as AnyObject, "active" : active as Bool as AnyObject, "current" : current as AnyObject, "timeActivated" : timeActivated as AnyObject]
        
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        
        groupRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            let group = snapshot.value as! String
            print("group3: " + group)
            
            // Create new child with generated id
            let newData = databaseRef.child("Chore").child(group).childByAutoId()
            
            // Save id to local item and backend
            let id = newData.key
            self.id = id
            chore["id"] = id as AnyObject?
            
            var toAssign: [String : AnyObject] = [:]
            var index = 0
            for x in self.assigned {
                toAssign.updateValue(index as AnyObject, forKey: x)
                index += 1
            }
            
            chore["assigned"] = toAssign as AnyObject?
            newData.setValue(chore)
        })
        
    }
    
    // For push/complete
    func update(updatingCurrent: Bool) {
        if updatingCurrent {
            updateCurrent()
        }
        updateTime()
        updateActive()
        
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        
        groupRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            print("update")
            let group = snapshot.value as! String
            print("before choreRef")
            let choreRef = databaseRef.child("Chore").child(group).child(self.id)
            print("after choreRef")
            
            let toUpdate : [String : AnyObject] = ["active" : self.active as Bool as AnyObject, "current" : self.current as AnyObject, "timeActivated" : self.timeActivated as AnyObject]
            
            choreRef.updateChildValues(toUpdate)
            
            if !updatingCurrent {
                print("gonna send notification from chore.update")
                let assignedRef = choreRef.child("assigned")
                var toAssign: [String] = []
                func addAssigned(_ completionHandler: @escaping CompletionHandler) {
                    var counter = 0
                    assignedRef.queryOrderedByValue().observe(.childAdded, with: {snap in
                        let toAdd = snap.key
                        toAssign.append(toAdd)
                        counter += 1
                        if counter >= self.assigned.count {
                            completionHandler(true)
                        }
                    })
                }
                addAssigned() { (success) in
                    let username = toAssign[self.current]
                    let message = "It's your turn to " + self.name + "!"
                    sendNotification(username: username, message: message)
                }
            }
        })
    }
    
    // For just updating values
    func update() {
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        
        groupRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            print("update")
            let group = snapshot.value as! String
            let choreRef = databaseRef.child("Chore").child(group).child(self.id)
            var toUpdate : [String : AnyObject] = ["name" : self.name as AnyObject, "active" : self.active as Bool as AnyObject, "current" : self.current as AnyObject, "timeActivated" : self.timeActivated as AnyObject]
            var toAssign: [String : AnyObject] = [:]
            var index = 0
            for x in self.assigned {
                toAssign.updateValue(index as AnyObject, forKey: x)
                index += 1
            }
            toUpdate["assigned"] = toAssign as AnyObject?
            choreRef.updateChildValues(toUpdate)
        })
    }
    
    func delete() {
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        
        groupRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            let group = snapshot.value as! String
            print("group2: " + group)
            
            let choreToRemove = databaseRef.child("Chore").child(group).child(self.id)
            choreToRemove.removeValue()
        })
        if active {
            activeChores.remove(object: self)
        } else {
            inactiveChores.remove(object: self)
        }
    }
    
    // Remove a user from assigned
    func removeFromAssigned(uid: String) {
        if assigned.contains(uid) {
            let index = assigned.index(of: uid)
            assigned.remove(object: uid)
            updateCurrent(index: index!)
            if assigned.count == 0 {
                delete()
            } else {
                update()
            }
        }
    }
    
    func updateCurrent() {
        if self.current < self.assigned.count - 1 {
            self.current += 1
        } else {
            self.current = 0
        }
    }
    
    func updateCurrent(index: Int) {
        if current > index {
            current -= 1
        }
        if current >= assigned.count {
            current = 0
        }
    }
    
    func updateTime() {
        let time = NSDate()
        self.timeActivated = formatDate(date: time)
    }
    
    func updateActive() {
        self.active = !self.active
    }
    
    public static func ==(lhs: Chore, rhs: Chore) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
}
