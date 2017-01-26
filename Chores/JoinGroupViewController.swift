//
//  JoinGroupViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/28/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}

class JoinGroupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var groupCodeTextField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    var uid = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        groupCodeTextField.delegate = self
        
        self.uid = (FIRAuth.auth()?.currentUser?.uid)!
        setJoin()
        setTextField()
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func joinPressed(_ sender: UIButton) {
        let codeRef = FIRDatabase.database().reference().child("Passcode").child(groupCodeTextField.text!)
        codeRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            if !snapshot.exists() {
                self.groupCodeTextField.shake()
                print("passcode doesn't exist")
            } else {
                let groupid = snapshot.value as! String
                let ref = FIRDatabase.database().reference()
                ref.child("User").child(self.uid).child("group").setValue(groupid)
                ref.child("Group").child(groupid).child("members").child(self.uid).setValue(true)
                loadUsers() { (success) in
                    let delayInSeconds = 2.0
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                        let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                        let MainScreenViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main")
                        self.present(MainScreenViewController, animated: true, completion: nil)
                    }
                }
                
            }
            
        })
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (groupCodeTextField.text?.isEmpty)! {
            print("enabled")
            self.joinButton.isEnabled = false
        } else {
            print("not enabled")
            self.joinButton.isEnabled = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func setJoin() {
        joinButton.setTitleColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0), for: .normal)
        joinButton.titleLabel!.font = UIFont(name: "Lato-Regular", size: 18)
    }
    
    func setTextField() {
        let border = CALayer()
        let width = CGFloat(1.5)
        
        let screen = self.view.frame
        
        groupCodeTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        groupCodeTextField.center.x = self.view.center.x
        groupCodeTextField.center.y = self.view.center.y
        
        border.borderColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0).cgColor
        border.frame = CGRect(x: 0, y: groupCodeTextField.frame.size.height - width, width:  groupCodeTextField.frame.size.width, height: groupCodeTextField.frame.size.height)
        
        border.borderWidth = width
//        groupCodeTextField.layer.addSublayer(border)
        groupCodeTextField.layer.masksToBounds = true
        
        groupCodeTextField.attributedPlaceholder = NSAttributedString(string: "Group code...", attributes: [NSForegroundColorAttributeName: UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)])
        groupCodeTextField.textColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        groupCodeTextField.font = UIFont(name: "Lato-Regular", size: 18)
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
