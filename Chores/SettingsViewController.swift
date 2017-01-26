//
//  SettingsViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/21/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FirebaseAuth
import FirebaseDatabase

protocol CollectionViewCellDelegate: class {
    func showAlert(user: CollectionViewUser);
}

var passcode : String = ""

class SettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewCellDelegate {
    
    // Attributes
    @IBOutlet weak var membersCollection: UICollectionView!
    @IBOutlet weak var passcodeLabel: UILabel!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgrounView: UIView!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var leaveButton: UIButton!
    
    var removeHandle : FIRDatabaseHandle!
    var addHandle : FIRDatabaseHandle!
    var firData : FIRDatabaseReference = FIRDatabaseReference()
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        firData = FIRDatabase.database().reference().child("Group").child(curUser.gid).child("members")
        
        removeHandle = firData.observe(.childRemoved, with: {(snapshot) -> Void in
            print("removeHandle")
            let member = snapshot.key
            if let user = userForId(id: member)  {
                userState.noRepeats[member] = false
                userState.users.remove(object: user)
                print("here")
            }
            self.membersCollection.reloadData()
        })
        
        addHandle = firData.observe(.childAdded, with: {(snapshot) -> Void in
            print("addHandle")
            let member = snapshot.key
            if !userState.noRepeats.keys.contains(member) {
                
                userState.noRepeats[member] = true
                obtainInfo(id: member) { (success) in
                    self.membersCollection.reloadData()
                    print("Here")
                }
            }
            
            
        })
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        firData.removeObserver(withHandle: removeHandle)
        firData.removeObserver(withHandle: addHandle)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        membersCollection.dataSource = self
        membersCollection.delegate = self
        membersCollection.reloadData()
        
        setBackground()
        setCollectionView()
        setLogOutButton()
        setLeaveButton()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.membersCollection?.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        
        let currentUser = FIRAuth.auth()?.currentUser
        let uid = currentUser?.uid
        let databaseRef = FIRDatabase.database().reference()
        let ref = databaseRef.child("User").child(uid!).child("group")
        
        self.passcodeLabel.text = "Code: " + passcode
        ref.observeSingleEvent(of: .value, with: {
            (snapshot) in
            print("Settings viewDidLoad")
            let group = snapshot.value as! String
            /*
             let groupNameRef = databaseRef.child("Group").child(group).child("name")
             groupNameRef.observeSingleEvent(of: .value, with: { (snap) in
             let groupName = snap.value as! String
             self.title = groupName
             })
             */
            let passcodeRef = databaseRef.child("Group").child(group).child("passcode")
            passcodeRef.observeSingleEvent(of: .value, with: { (snap) in
                let code = snap.value as! String
                self.passcodeLabel.text = "Code: " + code
            })
            //            self.passcodeLabel.text = passcode as! String?
        })
    }
    
    // Stuff for adjusting height
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let observedObject = object as? UICollectionView, observedObject == self.membersCollection {
            updateViewConstraints()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("removing observer")
        super.viewWillDisappear(animated)
        self.membersCollection?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        heightConstraint.constant = membersCollection.contentSize.height
        print("setting height to")
        print(membersCollection.contentSize.height)
    }
    
    //TAKES A GROUPID and user ID and removes said user from said group and does necessary database changes.
    func removeUser(groupID: String, userID: String) {
        FIRDatabase.database().reference().child("Group").child(groupID).child("members").child(userID).removeValue()
        FIRDatabase.database().reference().child("User").child(userID).child("group").setValue("")
        let groupDatabase = FIRDatabase.database().reference().child("Group").child(groupID)
        groupDatabase.observeSingleEvent(of: .value, with: {(snapshot) in
            if !snapshot.hasChild("members") {
                print("removing")
                let value = snapshot.value as! NSDictionary
                let password = value["passcode"] as! String
                groupDatabase.removeValue()
                FIRDatabase.database().reference().child("Chore").child(groupID).removeValue()
                FIRDatabase.database().reference().child("Passcode").child(password).removeValue()
                
            }
        })
        if userID == FIRAuth.auth()?.currentUser?.uid {
            
            let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
            let viewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "GroupPrompt")
            self.present(viewController, animated: true, completion: nil)
            
        }
        else {
            var newUsers: [CollectionViewUser] = [CollectionViewUser]()
            
            //Itd be a shame if a user got added twice
            var newNoRepeats: [String : Bool] = [String: Bool]()
            
            for user in userState.users{
                if user.getUid() != userID{
                    newUsers.append(user)
                    newNoRepeats[user.getUid()] = true
                }
            }
            
            userState.noRepeats = newNoRepeats
            userState.users = newUsers
            membersCollection.reloadData()
            
        }
        
        
        
    }
    internal func showAlert(user: CollectionViewUser) {
        // Create alert to make sure they wanna remove
        let alertController = UIAlertController(title: "Remove", message: "Remove user?" , preferredStyle: .alert)
        
        // Yes pressed. Do all actions here.
        let leaveAction = UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction) in
            print("removing")
            
            let uid = user.getUid()
            // Remove user from all chores
            for chore in activeChores {
                chore.removeFromAssigned(uid: uid)
            }
            
            for chore in inactiveChores {
                chore.removeFromAssigned(uid: uid)
            }
            
            // Remove user from group
            let databaseRef = FIRDatabase.database().reference()
            let ref = databaseRef.child("User").child(uid).child("group")
            
            //Find group id, then use removeUser function
            ref.observeSingleEvent(of: .value, with: {
                (snapshot) in
                let group = snapshot.value as! String
                print(group)
                self.removeUser(groupID: group, userID: uid)
            })
            
            activeChores.removeAll()
            inactiveChores.removeAll()
            
        })
        
        // No pressed. Cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(leaveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    // User leaving group. Prompt user to confirm. Then remove userid from assigned for every chore, deleting chore if no one assigned. Then remove userid from group memebers. Delete group if no one in group.
    @IBAction func leavePressed(_ sender: UIButton) {
        
        // Create alert to make sure they wanna leave
        let alertController = UIAlertController(title: "Leave", message: "Are you sure you want to leave?" , preferredStyle: .alert)
        
        // Yes pressed. Do all actions here.
        let leaveAction = UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction) in
            print("leaving")
            
            let currentUser = FIRAuth.auth()?.currentUser
            let uid = currentUser?.uid
            // Remove user from all chores
            for chore in activeChores {
                chore.removeFromAssigned(uid: uid!)
            }
            for chore in inactiveChores {
                chore.removeFromAssigned(uid: uid!)
            }
            
            // Remove user from group
            let databaseRef = FIRDatabase.database().reference()
            let ref = databaseRef.child("User").child(uid!).child("group")
            
            ref.observeSingleEvent(of: .value, with: {
                (snapshot) in
                let group = snapshot.value as! String
                self.removeUser(groupID: group, userID: uid!)
            })
            
            activeChores.removeAll()
            inactiveChores.removeAll()
            
            // Go to group prompt page
            print("leaving")
            let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
            let viewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "GroupPrompt")
            self.present(viewController, animated: true, completion: nil)
            
        })
        
        // No pressed. Cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(leaveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        
        
    }
    
    // Need to clear everything
    @IBAction func logoutPressed(_ sender: UIButton) {
        activeChores.removeAll()
        inactiveChores.removeAll()
        totalChores.removeAll()
        
        // Remove listeners
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        
        print(1)
        groupRef.observeSingleEvent(of: .value, with: {
            (snapshot) in
            print("group")
            print(2)
            let group = snapshot.value as! String
            let choresRef = databaseRef.child("Chore").child(group)
            choresRef.removeAllObservers()
        })
        
        // sign the user out of the Firebase app
        print("logging out")
        try! FIRAuth.auth()!.signOut()
        
        //signs the user out of Facebook app
        FBSDKAccessToken.setCurrent(nil)
        
        
        //Move user back to login
        let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let viewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "initial")
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func infoPressed(_ sender: UIBarButtonItem) {
        // Create alert to show info
        let alertController = UIAlertController(title: "Work used", message: "Icons - https://icons8.com/ \n Images - http://papers.co/my69-house-swimmingpool-vacation-nature-city/" , preferredStyle: .alert)
        
        // Okay pressed
        let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        alertController.addAction(okayAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: Collection view
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(userState.users.count)
        
        return userState.users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "membersCell", for: indexPath) as! MembersCollectionViewCell
        print(indexPath)
        let user : CollectionViewUser = userState.users[indexPath.row]
        
        cell.profileImage?.image = user.getImage()
        cell.nameLabel.text = user.getName().characters.split{$0 == " "}.map(String.init)[0]
        cell.user = user
        cell.delegate = self
        
        if cell.user.getUid() == (FIRAuth.auth()?.currentUser)!.uid {
            cell.deleteButton.isHidden = true
        }
        cell.setUI()
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI
    func setCodeLabel() {
        self.passcodeLabel.textColor = UIColor(red:0.41, green:0.41, blue:0.41, alpha:1.0)
    }
    
    func setNavigationBar() {
        
        navigationController?.navigationBar.barTintColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Lato-Semibold", size: 25)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    func setBackground() {
        self.view.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
        self.backgrounView.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    
    func setCollectionView() {
        self.membersCollection.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    
    func setLogOutButton() {
        logOutButton.setTitleColor(UIColor(red:1.00, green:0.35, blue:0.30, alpha:1.0), for: UIControlState())
        logOutButton.titleLabel!.font =  UIFont(name: "Lato-Regular", size: 25)
        
        logOutButton.backgroundColor = UIColor.white
        logOutButton.layer.cornerRadius = 7
    }
    
    func setLeaveButton() {
        leaveButton.setTitleColor(UIColor.white, for: UIControlState())
        leaveButton.titleLabel!.font =  UIFont(name: "Lato-Regular", size: 25)
        
        leaveButton.backgroundColor = UIColor(red:1.00, green:0.35, blue:0.30, alpha:1.0)
        leaveButton.layer.cornerRadius = 7
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
