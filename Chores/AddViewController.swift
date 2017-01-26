//
//  AddViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/20/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

/*
extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            if i != j {
                swap(&self[i], &self[j])
            }
        }
    }
}
*/

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

func formatDate(date: NSDate) -> String {
    var formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
    let defaultTimeZoneStr = formatter.string(from: date as Date)
    // : "2016-05-10 20:55:06 +0300" - Local (GMT +3)
    formatter.timeZone = NSTimeZone(abbreviation: "UTC") as TimeZone!
    let utcTimeZoneStr = formatter.string(from: date as Date)
    return utcTimeZoneStr
}

class AddViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // Objects
    var assignedUsers: [String] = []
    
    @IBOutlet weak var choreNameTextField: UITextField!
    
    @IBOutlet weak var activeSwitch: UISwitch!
    
    @IBOutlet weak var assignedCollection: UICollectionView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var backgroundView: UIView!
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        assignedCollection.dataSource = self
        assignedCollection.delegate = self
        assignedCollection.allowsMultipleSelection = true
        choreNameTextField.delegate = self
        scrollView.delegate = self
        
        setBackground()
        setNavigationBar()
        setTextField()
        setCollectionView()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        tap.delegate = self
        
        self.assignedCollection?.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        print("done")
    }
    
    // For collection view size
    override func viewWillLayoutSubviews() {
        assignedCollection.collectionViewLayout.invalidateLayout()
    }
    
    // Stuff for adjusting height
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let observedObject = object as? UICollectionView, observedObject == self.assignedCollection {
            self.updateViewConstraints()
        }
    }
    
    // Scrolling
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.assignedCollection?.removeObserver(self, forKeyPath: "contentSize")
    }
    // Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userState.users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        let user : CollectionViewUser = userState.users[indexPath.row]
        
        cell.imageView?.image = user.getImage()
        cell.nameLabel.text = user.getName().characters.split{$0 == " "}.map(String.init)[0]
        cell.user = user
        cell.setUI()
        return cell
    }
    
    // Select
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        //cell.backgroundColor = UIColor.grayColor()
        
        assignedUsers.append(cell.user.getUid())
        
        /*
        cell.layer.masksToBounds = false;
        cell.layer.shadowOffset = CGSize(width: 5.0, height: 5.0);
        cell.layer.shadowRadius = 5;
        cell.layer.shadowOpacity = 0.75;
        */
        cell.select()
        
        if !(choreNameTextField.text?.isEmpty)! {
            self.doneButton.isEnabled = true
        }
    }
    
    // Deselect
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        
        let selectedUser = cell.user
        assignedUsers = assignedUsers.filter() {
            $0 != selectedUser?.getUid()
        }
        
//        cell.layer.shadowOpacity = 0
        cell.deselect()
        if assignedUsers.count == 0 {
            doneButton.isEnabled = false
        }
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        let timeActivated = NSDate()
        let formatedDate = formatDate(date: timeActivated)
        
        print("assignedUsers before shuffling")
        print(assignedUsers)
        assignedUsers.shuffle()
        print("after")
        print(assignedUsers)
        
        let toAdd = Chore(name: choreNameTextField.text!, id: "", active: activeSwitch.isOn, assigned: assignedUsers, current: 0, timeActivated: formatedDate)
        toAdd?.saveChore()
        print(assignedUsers)
        
        if activeSwitch.isOn {
            let username = assignedUsers[0]
            let message = "It's your turn to " + choreNameTextField.text! + "!"
            
            sendNotification(username: username, message: message)
        }
        
        self.choreNameTextField.resignFirstResponder()
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        self.choreNameTextField.resignFirstResponder()
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // Text field stuff
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (choreNameTextField.text?.isEmpty)! {
            self.doneButton.isEnabled = false
        } else if assignedUsers.count > 0 {
            self.doneButton.isEnabled = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.choreNameTextField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        self.view.endEditing(true)
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == choreNameTextField {
            return false
        }
        return true
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UI
    // For collection view size
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // Compute the dimension of a cell for an NxN layout with space S between
        // cells.  Take the collection view's width, subtract (N-1)*S points for
        // the spaces between the cells, and then divide by N to find the final
        // dimension for the cell's width and height.
        print("setting layout")
        
        let screenWidth = self.view.frame.width
        let cellsAcross: CGFloat = 3
        let spaceBetweenCells: CGFloat = 10
        let dim = (collectionView.bounds.width - (cellsAcross - 1) * spaceBetweenCells) / cellsAcross
        return CGSize(width: dim, height: dim)
    }
    
    func setNavigationBar() {
        navigationController?.navigationBar.barTintColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Lato-Semibold", size: 25)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    func setBackground() {
        self.view.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
        self.backgroundView.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    
    func setTextField() {
        self.choreNameTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        self.choreNameTextField.backgroundColor = UIColor.white
        self.choreNameTextField.borderStyle = UITextBorderStyle.none
    }
    
    func setCollectionView() {
        self.assignedCollection.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        collectionHeightConstraint.constant = assignedCollection.contentSize.height
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
