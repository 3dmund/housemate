//
//  CreateGroupViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/28/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class CreateGroupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var groupNameTextField: UITextField!
    
    @IBOutlet weak var createButton: UIButton!
    
    var uid = String()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        groupNameTextField.delegate = self
        
        self.uid = (FIRAuth.auth()?.currentUser?.uid)!
        self.view.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        setCreate()
        setTextField()
    }

    // Actions
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createPressed(_ sender: UIButton) {
        self.create()
    }
    
    func create() {
        let codeRef = FIRDatabase.database().reference().child("Passcode")
        codeRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            var passcode = String()
            var newNumber = true
            while(newNumber) {
                passcode = getPassCode()
                if snapshot.hasChild(passcode) {
                    passcode = getPassCode()
                } else {
                    newNumber = false
                }
            }
            
            
            //Informaiton to save to backend
            let toSave = ["name": self.groupNameTextField.text!, "passcode" : passcode, "members": [self.uid: true]] as [String : Any]
            
            let ref = FIRDatabase.database().reference().child("Group").childByAutoId()
            let groupID = ref.key
            ref.setValue(toSave)
            
            FIRDatabase.database().reference().child("User").child(self.uid).child("group").setValue(groupID)
            codeRef.child(passcode).setValue(groupID)
            loadUsers() {
                (success) in
                let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                let MainScreenViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main")
                self.present(MainScreenViewController, animated: true, completion: nil)
            }
            
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("como?")
        if (groupNameTextField.text?.isEmpty)! {
            print("enabled")
            self.createButton.isEnabled = false
        } else {
            print("not enabled")
            self.createButton.isEnabled = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        print("ending editing")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.create()
        return true
    }
    
    func setCreate() {
        createButton.setTitleColor(UIColor.white, for: .normal)
        createButton.titleLabel!.font = UIFont(name: "Lato-Regular", size: 18)
    }
    
    func setTextField() {
        let border = CALayer()
        let width = CGFloat(1.5)
        
        let screen = self.view.frame
        
        groupNameTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        groupNameTextField.center.x = self.view.center.x
        groupNameTextField.center.y = self.view.center.y
        
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: groupNameTextField.frame.size.height - width, width:  groupNameTextField.frame.size.width, height: groupNameTextField.frame.size.height)
        
        border.borderWidth = width
//        groupNameTextField.layer.addSublayer(border)
        groupNameTextField.layer.masksToBounds = true
        
        groupNameTextField.attributedPlaceholder = NSAttributedString(string: "Group name...", attributes: [NSForegroundColorAttributeName: UIColor.white])
        groupNameTextField.textColor = UIColor.white
        groupNameTextField.font = UIFont(name: "Lato-Regular", size: 18)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
