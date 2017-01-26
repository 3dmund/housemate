//
//  SignUpViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/29/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Attributes
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var backButton: UIButton!
    var screen: CGRect = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screen = self.view.frame
        
        // Do any additional setup after loading the view.
        setNameTextField()
        setEmailTextField()
        setPasswordTextField()
        setSignUpButton()
        setProfilePicture()
        setSpinner()
        setBackButton()
        
        self.nameTextField.delegate = self
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectProfilePicture(recognizer:)))
        self.profilePicture.addGestureRecognizer(tapRecognizer)
    }
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        self.signUp()
    }
    
    func signUp() {
        if (nameTextField.text! == "") {
            self.nameTextField.shake()
            self.emailTextField.shake()
            self.passwordTextField.shake()
            self.profilePicture.shake()
            let alertController : UIAlertController = UIAlertController(title: "Error", message: "Please enter a name.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alertController, animated: true, completion: nil)
        } else{
            
            
            FIRAuth.auth()?.createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!, completion: { (user, error) in
                if error != nil {
                    
                    self.nameTextField.shake()
                    self.emailTextField.shake()
                    self.passwordTextField.shake()
                    self.profilePicture.shake()
                    let message : String = error.debugDescription
                    
                    if (message.range(of: "MISSING_PASSWORD") != nil) {
                        let alertController : UIAlertController = UIAlertController(title: "Error", message: "No password was entered!", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                        self.present(alertController, animated: true, completion: nil)
                    }else if (message.range(of: "INVALID_EMAIL") != nil ){
                        let alertController : UIAlertController = UIAlertController(title: "Error", message: "Invalid email was entered!", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                        self.present(alertController, animated: true, completion: nil)                }
                    else if (message.range(of: "WEAK_PASSWORD") != nil)
                    {
                        let alertController : UIAlertController = UIAlertController(title: "Error", message: "Password must be 6 characters or longer.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                        self.present(alertController, animated: true, completion: nil)
                    }else if (message.range(of: "EMAIL_ALREADY") != nil)
                    {
                        let alertController : UIAlertController = UIAlertController(title: "Error", message: "Email already in use.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                        self.present(alertController, animated: true, completion: nil)
                    }
                } else {
                    self.dismissKeyboard()
                    self.load()
                    //User logs in
                    let ref = FIRDatabase.database().reference()
                    print(user!.uid)
                    
                    
                    let imageData: NSData = UIImageJPEGRepresentation(self.profilePicture.image!, 0.5)! as NSData
                    //                                strBase64 = imageData.base64EncodedString(options: .Encoding64CharacterLineLength)
                    let newUser = User(name: self.nameTextField.text!, email: self.emailTextField.text!, picture: imageData, facebook: false, uid: user!.uid)!
                    print("about to add user w/ name: " + self.nameTextField.text! + "email" + self.emailTextField.text!)
                    
                    newUser.addUser() {
                        (success) -> Void in
                        print("signUpToGroup")
                        
                        curUser.email = newUser.email
                        curUser.image = UIImage(data: newUser.picture as Data)!
                        curUser.name = newUser.name
                        curUser.id = newUser.uid
                        
                        self.performSegue(withIdentifier: "signUpToGroup", sender: nil)
                        
                        print("User logged into Firebase")
                    }
                }
            })
        }
    }
    
    func selectProfilePicture(recognizer: UIGestureRecognizer) {
        print("poop")
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        print("selecting")

        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        profilePicture.image = selectedImage.circle
        dismiss(animated: true, completion: nil)

    }
    

    @IBAction func backPressed(_ sender: UIButton) {
//        dismiss(animated: true, completion: nil)
        print("back pressed")
        navigationController?.popViewController(animated: true)
    }
    
    // Text field stuff
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.signUp()
        return true
    }
    
    func load() {
        self.profilePicture.isHidden = true
        self.nameTextField.isHidden = true
        self.emailTextField.isHidden = true
        self.passwordTextField.isHidden = true
        self.signUpButton.isHidden = true
        self.backButton.isHidden = true
        self.loadingSpinner.isHidden = false
        self.loadingSpinner.startAnimating()
    }
    
    
    // MARK: UI
    
    func setNameTextField() {
        nameTextField.layer.cornerRadius = 20
        nameTextField.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
        nameTextField.borderStyle = UITextBorderStyle.none;
        nameTextField.font = UIFont.init(name: "Lato-Regular", size: 18)
        nameTextField.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        
        nameTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        nameTextField.center.x = self.view.center.x
        nameTextField.center.y = self.view.center.y
    }
    
    func setEmailTextField() {
        emailTextField.layer.cornerRadius = 20
        emailTextField.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
        emailTextField.borderStyle = UITextBorderStyle.none;
        emailTextField.font = UIFont.init(name: "Lato-Regular", size: 18)
        emailTextField.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        
        emailTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        emailTextField.center.x = self.view.center.x
        emailTextField.center.y = screen.height * 0.58
    }
    
    func setPasswordTextField() {
        passwordTextField.layer.cornerRadius = 20
        passwordTextField.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
        passwordTextField.borderStyle = UITextBorderStyle.none;
        passwordTextField.font = UIFont.init(name: "Lato-Regular", size: 18)
        passwordTextField.textColor = UIColor(red:0.58, green:0.60, blue:0.60, alpha:1.0)
        
        passwordTextField.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        passwordTextField.center.x = self.view.center.x
        passwordTextField.center.y = screen.height * 0.66
    }
    
    func setSignUpButton() {
        signUpButton.layer.cornerRadius = 20
        signUpButton.layer.borderWidth = 1
        signUpButton.layer.borderColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0).cgColor
        signUpButton.layer.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0).cgColor
        signUpButton.titleLabel!.font =  UIFont(name: "Lato-Regular", size: 18)
        signUpButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        
        signUpButton.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        signUpButton.center.x = self.view.center.x
        signUpButton.center.y = screen.height * 0.74
    }
    
    
    func setSpinner() {
        loadingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        loadingSpinner.isHidden = true
//        loadingSpinner.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        loadingSpinner.color = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setProfilePicture() {
        self.profilePicture.image = self.profilePicture.image?.circle
        profilePicture.frame = CGRect(x: 0, y: 0, width: screen.height * 0.2, height: screen.height * 0.2)
        profilePicture.center.x = self.view.center.x
        profilePicture.center.y = screen.height * 0.25
    }
    
    func setBackButton() {
        backButton.frame = CGRect(x: screen.width * 0.05, y: screen.height * 0.05, width: screen.height * 0.05, height: screen.height * 0.05)
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
