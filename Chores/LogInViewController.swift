//
//  LogInViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/29/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    // Attributes
    
    
    @IBOutlet weak var houseImage: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var forgotLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    var screen: CGRect = CGRect()

    override func viewDidLoad() {
        super.viewDidLoad()

        screen = self.view.frame
            
        // Do any additional setup after loading the view.
        setBackButton()
        setHouseImage()
        setEmailTextField()
        setPasswordTextField()
        setLogInButton()
        setForgotLabel()
        setSpinner()
        
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    @IBAction func logInPressed(_ sender: UIButton) {
        self.logIn()
    }
    
    func logIn() {
        FIRAuth.auth()?.signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!, completion: { (user, error) in
            
            if error != nil {
                print("incorrect")
                self.emailTextField.shake()
                self.passwordTextField.shake()
                self.houseImage.shake()
            }
            else {
                self.view.endEditing(true)
                self.load()
                let currentUser = FIRAuth.auth()?.currentUser
                
                let userRef = FIRDatabase.database().reference().child("User").child((currentUser?.uid)!)
                let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                userRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
                    if (!snapshot.exists() || (snapshot.value as! [String:AnyObject])["group"] as! String == "") {
                        //No, then go to groupprompt
                        print("initialToGroup")
                        self.performSegue(withIdentifier: "logInToGroup", sender: nil)
                    }
                        
                        
                    else {
                        //Yes, then go to list
                        
                        loadUsers() { (success) in
                            
                            let delayInSeconds = 2.0
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                                let MainScreenViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main")
                                self.present(MainScreenViewController, animated: true, completion: nil)
                            }
                        }
                        
                    }
                })
            }
            
            
        })
    }
    
    func load() {
        self.houseImage.isHidden = true
        self.emailTextField.isHidden = true
        self.passwordTextField.isHidden = true
        self.logInButton.isHidden = true
        self.backButton.isHidden = true
        self.forgotLabel.isHidden = true
        self.loadingSpinner.isHidden = false
        self.loadingSpinner.startAnimating()
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // Text field stuff
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.logIn()
        return true
    }
    
    // MARK: UI
    
    func setSpinner() {
        loadingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        loadingSpinner.isHidden = true
        //        loadingSpinner.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        loadingSpinner.color = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
    }
    
    func setBackButton() {
        backButton.frame = CGRect(x: screen.width * 0.05, y: screen.height * 0.05, width: screen.height * 0.05, height: screen.height * 0.05)
    }
    
    func setHouseImage() {
        houseImage.frame = CGRect(x: 0, y: 0, width: screen.height * 0.2, height: screen.height * 0.2)
        houseImage.center.x = self.view.center.x
        houseImage.center.y = screen.height * 0.25
    }
    
    func setEmailTextField() {
        emailTextField.layer.cornerRadius = 20
        emailTextField.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
        emailTextField.borderStyle = UITextBorderStyle.none;
        emailTextField.font = UIFont.init(name: "Lato-Regular", size: 18)
        emailTextField.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        
        emailTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        emailTextField.center.x = self.view.center.x
        emailTextField.center.y = self.view.center.y
    }
    
    func setPasswordTextField() {
        passwordTextField.layer.cornerRadius = 20
        passwordTextField.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
        passwordTextField.borderStyle = UITextBorderStyle.none;
        passwordTextField.font = UIFont.init(name: "Lato-Regular", size: 18)
        passwordTextField.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        
        passwordTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        passwordTextField.center.x = self.view.center.x
        passwordTextField.center.y = screen.height * 0.58
    }
    
    func setLogInButton() {
        logInButton.layer.cornerRadius = 20
        logInButton.layer.borderWidth = 1
        logInButton.layer.borderColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0).cgColor
        logInButton.titleLabel!.font =  UIFont(name: "Lato-Regular", size: 18)
        logInButton.setTitleColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0), for: UIControlState.normal)
        
        logInButton.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        logInButton.center.x = self.view.center.x
        logInButton.center.y = screen.height * 0.66
    }

    func setForgotLabel() {
        let customString = NSMutableAttributedString(string: "Forgot login details? Click here.", attributes: [NSFontAttributeName:UIFont(name: "Lato-Regular", size: 15)!])
        customString.addAttribute(NSFontAttributeName, value: UIFont(name: "Lato-Bold", size: 15)!, range: NSRange(location:22,length:11))
        
        forgotLabel.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        forgotLabel.attributedText = customString
        
        forgotLabel.sizeToFit()
        forgotLabel.center.x = self.view.center.x
        forgotLabel.center.y = screen.height * 0.73
        
        let forgotTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.forgot(recognizer:)))
        self.forgotLabel.addGestureRecognizer(forgotTapRecognizer)
    }
    
    func forgot(recognizer: UIGestureRecognizer) {
        let email = self.emailTextField.text
        if (email?.isEmpty)! {
            // Create alert to tell user to enter email
            let alertController = UIAlertController(title: "Email needed", message: "Please enter email in text field." , preferredStyle: .alert)
            
            // Okay pressed
            let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(okayAction)
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            FIRAuth.auth()?.sendPasswordReset(withEmail: email!) { error in
                if error != nil {
                    let alertController = UIAlertController(title: "Error", message: "Please make sure entered email is correct." , preferredStyle: .alert)
                    
                    // Okay pressed
                    let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    let alertController = UIAlertController(title: "Check email", message: "Password reset email sent." , preferredStyle: .alert)
                    
                    // Okay pressed
                    let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
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
