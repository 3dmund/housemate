//
//  MainViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/19/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UIKit
import UIKit.UIGestureRecognizerSubclass

var activeChores : [Chore] = []
var inactiveChores : [Chore] = []
//Stores all chores and whether they active
var totalChores : [String : Bool] = [:]

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension UIColor {
    static func imageWithBackgroundColor(image: UIImage, bgColor: UIColor) -> UIColor {
        let size = CGSize(width: 70, height: 70)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        
        let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        context!.setFillColor(bgColor.cgColor)
        context!.addRect(rectangle)
        context!.drawPath(using: .fill)
        
        context?.draw(image.cgImage!, in: rectangle)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return UIColor(patternImage: img!)
    }
}

func sendNotification(username: String, message: String) {
    print("sending notification to: " + username)
    let ref = FIRDatabase.database().reference().child("notifications")
    let notification: [String : AnyObject] = ["username" : username as AnyObject, "message" : message as AnyObject]
    ref.childByAutoId().setValue(notification)
}

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Attributes
    @IBOutlet weak var activeTable: UITableView!
    @IBOutlet weak var inactiveTable: UITableView!
    @IBOutlet weak var activeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inactiveHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var toDoLabel: UILabel!
    @IBOutlet weak var inactiveLabel: UILabel!
    
    var removeHandle : FIRDatabaseHandle!
    var addHandle : FIRDatabaseHandle!
    var changeHandle : FIRDatabaseHandle!
    var assignedHandle : FIRDatabaseHandle!
    var firData : FIRDatabaseReference = FIRDatabaseReference()
    var firDataQuery : FIRDatabaseQuery = FIRDatabaseQuery()
    
    override func viewWillAppear(_ animated: Bool) {
        print("View will appear")
        super.viewWillAppear(animated)
        let choresRef = FIRDatabase.database().reference().child("Chore").child(curUser.gid)
        firDataQuery = choresRef.queryOrdered(byChild: "timeActivated")
        firData = choresRef
        
        // MARK: Child added
        addHandle = firDataQuery.observe(.childAdded, with: {
            snapshot in
            print(2)
            let value = snapshot.value as! NSDictionary
            
            let name = value["name"] as! NSString
            let id = value["id"] as! NSString
            let active = value["active"] as! Bool
            let assigned = value["assigned"] as! [String : Int]
            //            let toAssign = Array(assign.keys)
            let current = value["current"] as! Int
            let timeActivated = value["timeActivated"] as! String
            
            let assignedRef = snapshot.ref.child("assigned")
            var toAssign: [String] = []
            
            //Make sure we don't add a chore twice
            let already = totalChores[id as String]
            if already == nil{
                func addAssigned(_ completionHandler: @escaping CompletionHandler) {
                    var counter = 0
                    self.assignedHandle = assignedRef.queryOrderedByValue().observe(.childAdded, with: {snap in
                        let toAdd = snap.key
                        toAssign.append(toAdd)
                        counter += 1
                        if counter >= assigned.count {
                            completionHandler(true)
                        }
                    })
                }
                addAssigned() { (success) in
                    totalChores[id as String] = active
                    let chore = Chore(name: name as String, id: id as String, active: active as Bool, assigned: toAssign, current: current as Int, timeActivated: timeActivated as String)
                    
                    chore?.setCurrentlyAssigned() {(success) in
                        if (chore?.active)! {
                            activeChores.append(chore!)
                        } else {
                            inactiveChores.insert(chore!, at: 0)
                        }
                        
                        if inactiveChores.count != 0 {
                            self.inactiveLabel.isHidden = false
                        }
                        if activeChores.count != 0 {
                            self.setToDo()
                        }
                        self.activeTable.reloadData()
                        self.inactiveTable.reloadData()
                        self.updateViewConstraints()
                    }
                }
            }
        })
        
        // MARK: Child removed
        removeHandle = firDataQuery.observe(.childRemoved, with: {
            snapshot in
            print("child removed")
            let value = snapshot.value as! NSDictionary
            
            let name = value["name"] as! NSString
            let id = value["id"] as! NSString
            let active = value["active"] as! Bool
            let assigned = value["assigned"] as! [String : Int]
            //            let toAssign = Array(assign.keys)
            let current = value["current"] as! Int
            let timeActivated = value["timeActivated"] as! String
            
            let assignedRef = snapshot.ref.child("assigned")
            var toAssign: [String] = []
            
            //Make sure chore has not been already removed. Not sure how that would happen
            let already = totalChores[id as String]
            if already != nil{
                func addAssigned(_ completionHandler: @escaping CompletionHandler) {
                    var counter = 0
                    self.assignedHandle = assignedRef.queryOrderedByValue().observe(.childAdded, with: {snap in
                        let toAdd = snap.key
                        toAssign.append(toAdd)
                        counter += 1
                        if counter >= assigned.count {
                            completionHandler(true)
                        }
                    })
                }
                addAssigned() { (success) in
                    totalChores[id as String] = nil
                    let chore = Chore(name: name as String, id: id as String, active: active as Bool, assigned: toAssign, current: current as Int, timeActivated: timeActivated as String)
                    activeChores.remove(object: chore!)
                    inactiveChores.remove(object: chore!)
                    if inactiveChores.count != 0 {
                        self.inactiveLabel.isHidden = false
                    }
                    if activeChores.count != 0 {
                        self.setToDo()
                    }
                    
                    self.activeTable.reloadData()
                    self.inactiveTable.reloadData()
                    self.updateViewConstraints()
                }
            }
        })
        
        // MARK: Child changed
        changeHandle = firData.observe(.childChanged, with: {
            snapshot in
            let value = snapshot.value! as! NSDictionary
            let name = value["name"] as! NSString
            let id = value["id"] as! NSString
            let active = value["active"] as! Bool
            let assigned = value["assigned"] as! [String : Int]
            //            let toAssign = Array(assign.keys)
            let current = value["current"] as! Int
            let timeActivated = value["timeActivated"] as! String
            
            let assignedRef = snapshot.ref.child("assigned")
            var toAssign: [String] = []
            
            //Make sure chore is not already where it should be
            //could potentially be a problem when initial data is trying to be loaded
            func addAssigned(_ completionHandler: @escaping CompletionHandler) {
                var counter = 0
                self.assignedHandle = assignedRef.queryOrderedByValue().observe(.childAdded, with: {snap in
                    let toAdd = snap.key
                    toAssign.append(toAdd)
                    counter += 1
                    if counter >= assigned.count {
                        completionHandler(true)
                    }
                })
            }
            addAssigned() { (success) in
                let toChange = Chore(name: name as String, id: id as String, active: active as Bool, assigned: toAssign, current: current as Int, timeActivated: timeActivated as String)
                toChange?.setCurrentlyAssigned() {(success) in
                    
                    totalChores[id as String] = active
                    if !active {
                        activeChores.remove(object: toChange!)
                        if !inactiveChores.contains(toChange!) {
                            inactiveChores.insert(toChange!, at: 0)
                        }
                    }
                    if active {
                        inactiveChores.remove(object: toChange!)
                        if !activeChores.contains(toChange!) {
                            activeChores.append(toChange!)
                        }
                    }
                    
                    if inactiveChores.count == 0 {
                        self.inactiveLabel.isHidden = true
                    } else {
                        self.inactiveLabel.isHidden = false
                    }
                    if activeChores.count == 0 {
                        self.setNoChores()
                    } else {
                        self.setToDo()
                    }
                    
                    self.activeTable.reloadData()
                    self.inactiveTable.reloadData()
                    self.updateViewConstraints()
                }
            }
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("chill")
        firDataQuery.removeObserver(withHandle: addHandle)
        firData.removeObserver(withHandle: changeHandle)
        firDataQuery.removeObserver(withHandle: removeHandle)
        firDataQuery.removeObserver(withHandle: assignedHandle)
    }
    
    // MARK: ViewDidLoad()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("MainViewController loaded")
        
        setTables()
        setBackground()
        setNavigationBar()
        setLabels()
        setNoChores()
        
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let groupRef = databaseRef.child("User").child(userId!).child("group")
        self.title = curUser.groupName
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        activeTable.frame = CGRect(x: activeTable.frame.origin.x, y: activeTable.frame.origin.y, width: activeTable.frame.size.width, height: activeTable.contentSize.height)
        inactiveTable.frame = CGRect(x: inactiveTable.frame.origin.x, y: inactiveTable.frame.origin.y, width: inactiveTable.frame.size.width, height: inactiveTable.contentSize.height)
    }
    
    override func viewDidLayoutSubviews(){
        activeTable.frame = CGRect(x: activeTable.frame.origin.x, y: activeTable.frame.origin.y, width: activeTable.frame.size.width, height: activeTable.contentSize.height)
        inactiveTable.frame = CGRect(x: inactiveTable.frame.origin.x, y: inactiveTable.frame.origin.y, width: inactiveTable.frame.size.width, height: inactiveTable.contentSize.height)
        activeTable.reloadData()
        inactiveTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.activeTable {
            return activeChores.count
        } else {
            return inactiveChores.count
        }
    }
    
    // Cell for row. Change labels for name and rating
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let databaseRef = FIRDatabase.database().reference()
        let currentUser = FIRAuth.auth()?.currentUser
        let userId = currentUser?.uid
        let storageRef = FIRStorage.storage().reference(forURL: "gs://chores-17bf7.appspot.com")
        if tableView == self.activeTable && indexPath[1] < activeChores.count{
            let cellIdentifier = "ActiveTableViewCell";
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ActiveTableViewCell
            let chore = activeChores[indexPath.row]
            cell.choreLabel.text = chore.name
            cell.chore = chore
            cell.setAssigned(assigned: chore.currentlyAssigned)
            cell.profileImage.image = chore.currentProPic
            
            /*
             let currentlyAssigned = chore.assigned[chore.current]
             let userRef = databaseRef.child("User").child(currentlyAssigned)
             
             userRef.observeSingleEvent(of: .value, with: {
             (snapshot) in
             let value = snapshot.value as! NSDictionary
             let name = value["name"] as! String
             if userRef.key == userId {
             cell.setAssigned(assigned: "Your")
             } else {
             cell.setAssigned(assigned: name)
             }
             let collectionUser = userForId(id: userRef.key)
             cell.profileImage.image = collectionUser?.getImage()
             
             
             })
             */
            cell.layoutMargins = UIEdgeInsets.zero
            
//            let bgColorView = UIView()
//            bgColorView.backgroundColor = UIColor.red
//            cell.selectedBackgroundView = bgColorView
            
            return cell
        }
        if tableView == self.inactiveTable && indexPath[1] < inactiveChores.count {
            let cellIdentifier = "InactiveTableViewCell";
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! InactiveTableViewCell
            let chore = inactiveChores[indexPath.row]
            cell.choreLabel.text = chore.name
            cell.chore = chore
            print("currently assigned: " + chore.currentlyAssigned)
            cell.setAssigned(assigned: chore.currentlyAssigned)
            cell.profileImage.image = chore.currentProPic
            
            /*
             let currentlyAssigned = chore.assigned[chore.current]
             
             let userRef = databaseRef.child("User").child(currentlyAssigned)
             
             userRef.observeSingleEvent(of: .value, with: {
             (snapshot) in
             let value = snapshot.value as! NSDictionary
             let name = value["name"] as! String
             
             if userRef.key == userId {
             cell.setAssigned(assigned: "You're")
             } else {
             cell.setAssigned(assigned: name)
             }
             let collectionUser = userForId(id: userRef.key)
             cell.profileImage.image = collectionUser?.getImage()
             
             })
             */
            cell.layoutMargins = UIEdgeInsets.zero
            return cell
        }
        return UITableViewCell()
        
    }
    
    // Swiping cell
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        /*
         if (editingStyle == UITableViewCellEditingStyle.delete) {
         if tableView == self.activeTable {
         let choreToDelete = activeChores[indexPath.row]
         choreToDelete.delete()
         activeChores.remove(object: choreToDelete)
         //                activeChores.remove(at: indexPath.section);
         activeTable.reloadData();
         }
         if tableView == self.inactiveTable {
         let choreToDelete = inactiveChores[indexPath.row]
         choreToDelete.delete()
         inactiveChores.remove(object: choreToDelete)
         //                inactiveChores.remove(at: indexPath.section);
         inactiveTable.reloadData();
         }
         }
         */
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        /*
         let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
         }
         edit.backgroundColor = UIColor.blue
         */
        
        
        let remind = UITableViewRowAction(style: .normal, title: "❕\n Remind") { action, index in
            print("remind button tapped")
            let chore = activeChores[indexPath.row]
            let username = chore.assigned[chore.current]
            let message = "Don't forget to " + chore.name + "!"
            sendNotification(username: username, message: message)
            
            // Create alert to show info
            let alertController = UIAlertController(title: "Reminded!", message: "" , preferredStyle: .alert)
            
            // Okay pressed
            let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(okayAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        remind.backgroundColor = UIColor.orange
        
        let delete = UITableViewRowAction(style: .normal, title: "✕\n Delete") { action, index in
            if tableView == self.activeTable {
                let choreToDelete = activeChores[indexPath.row]
                choreToDelete.delete()
                activeChores.remove(object: choreToDelete)
                self.activeTable.reloadData();
            }
            if tableView == self.inactiveTable {
                let choreToDelete = inactiveChores[indexPath.row]
                choreToDelete.delete()
                inactiveChores.remove(object: choreToDelete)
                self.inactiveTable.reloadData();
            }
            if inactiveChores.count == 0 {
                self.inactiveLabel.isHidden = true
            }
            if activeChores.count == 0 {
                self.setNoChores()
            }
            self.updateViewConstraints()
        }
        
        delete.backgroundColor = UIColor(red:1.00, green:0.20, blue:0.20, alpha:1.0)
        
        
        if tableView == activeTable {
            return [delete, remind]
        } else {
            return [delete]
        }
    }
    
    // Gestures
    func activeDidTap(recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.ended {
            let tapLocation = recognizer.location(in: self.activeTable)
            if let tappedIndexPath = activeTable.indexPathForRow(at: tapLocation) {
                if let tappedCell = self.activeTable.cellForRow(at: tappedIndexPath) as? ActiveTableViewCell {
                    // Swipe happened. Do stuff!
                    tappedCell.chore.update(updatingCurrent: true)
                }
            }
        }
    }
    
    func inactiveDidTap(recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.ended {
            let tapLocation = recognizer.location(in: self.inactiveTable)
            if let tappedIndexPath = inactiveTable.indexPathForRow(at: tapLocation) {
                if let tappedCell = self.inactiveTable.cellForRow(at: tappedIndexPath) as? InactiveTableViewCell {
                    // Swipe happened. Do stuff!
                    tappedCell.chore.update(updatingCurrent: false)
                }
            }
        }
    }
    
    func didPressDown(recognizer: UIGestureRecognizer) {
        print("didPressDown")
    }
    
    // MARK: UI
    func setBackground() {
        self.view.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .none
        return footer
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        activeHeightConstraint.constant = activeTable.contentSize.height
        inactiveHeightConstraint.constant = inactiveTable.contentSize.height
    }
    
    func setNavigationBar() {
        navigationController?.navigationBar.barTintColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Lato-Semibold", size: 25)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    func setLabels() {
        self.toDoLabel.font = UIFont(name: "Lato-Medium", size: 15)
        self.inactiveLabel.font = UIFont(name: "Lato-Medium", size: 15)
    }
    
    func setNoChores() {
        self.toDoLabel.text = "No chores to do!"
        self.toDoLabel.font = UIFont(name: "Lato-Medium", size: 20)
    }
    
    func setToDo() {
        self.toDoLabel.text = "To do"
        self.toDoLabel.font = UIFont(name: "Lato-Medium", size: 15)
    }
    
    func setTables() {
        activeTable.dataSource = self
        activeTable.delegate = self
        
        inactiveTable.dataSource = self
        inactiveTable.delegate = self
        
//        activeTable.allowsSelection = false
//        inactiveTable.allowsSelection = false
        
        activeTable.tableFooterView = UIView()
        inactiveTable.tableFooterView = UIView()
        
        activeTable.isScrollEnabled = false
        inactiveTable.isScrollEnabled = false
        
        activeTable.layoutMargins = UIEdgeInsets.zero
        activeTable.separatorInset = UIEdgeInsets.zero
        inactiveTable.layoutMargins = UIEdgeInsets.zero
        inactiveTable.separatorInset = UIEdgeInsets.zero
        
        let activeTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.activeDidTap(recognizer:)))
        let inactiveTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.inactiveDidTap(recognizer:)))
        self.activeTable.addGestureRecognizer(activeTapRecognizer)
        self.inactiveTable.addGestureRecognizer(inactiveTapRecognizer)
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        navigationItem.backBarButtonItem?.tintColor = UIColor.white
        
    }
    
    
}
