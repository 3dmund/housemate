//
//  ViewController.swift
//  Chores
//
//  Created by Edmund Tian on 12/18/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import FirebaseAuth

func printFonts() {
    for familyName in UIFont.familyNames {
        print("\n-- \(familyName) \n")
        for fontName in UIFont.fontNames(forFamilyName: familyName) {
            print(fontName)
        }
    }
}


extension UIImage {
    
    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!
        
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
    
}

class ViewController: UIViewController, FBSDKLoginButtonDelegate {

    var currentUser: User?
    var activeUser: FIRUser!
    
    // UI stuff
    var logoLabel: UILabel = UILabel()
    var usernameTextField: UITextField = UITextField()
    var passwordTextField: UITextField = UITextField()
    var loginButton: UIButton = UIButton()
    var loginFacebookButton: FBSDKLoginButton = FBSDKLoginButton()
    var signUpButton: UIButton = UIButton()
    var loginLabel: UILabel = UILabel()
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Check if user was previously logged in, and is 'cached' in memory
        //If user is, then ensure struct curUser is populated
        if let user = FIRAuth.auth()?.currentUser {
            load()
            let userRef = FIRDatabase.database().reference().child("User").child(user.uid)
            userRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
                if (!snapshot.exists() || (snapshot.value as! [String:AnyObject])["group"] as! String == "") {
                    //No, then go to groupprompt
                    self.performSegue(withIdentifier: "toGroupPrompt", sender: nil)
                }
                else {
                    //Yes, then go to list
                    loadUsers() { (success) in
                        print("finished loading users and presenting Main from ViewController")
                        let delayInSeconds = 2.0
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                            
                            // here code perfomed with delay
                            let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                            let MainScreenViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main")
                            self.present(MainScreenViewController, animated: true, completion: nil)
                            
                        }
                        
                    }
                    
                }
            })
            
            
        } else {
            self.addBackground()
            self.addLogoLabel()
            self.addFacebookLoginButton()
            self.addSignUpButton()
            self.addLoginLabel()
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        printFonts()
        
        // *****************************
        // REMOVE THIS LATER
        // *****************************
//      try! FIRAuth.auth()!.signOut()
        
        self.setSpinner()
        
    }
    
    public func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if (error != nil) {
            return
        } else if !result.isCancelled {
            self.load()
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)

            //User logs in
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                let ref = FIRDatabase.database().reference()
                ref.child("User").child(user!.uid).observeSingleEvent(of: .value, with: {(snapshot) -> Void in
                    //If its their first time logging in, snapshot will not exist
                    if !snapshot.exists() {
                        
                        self.fetchProfile( {(toPass, error) -> Void in
                            let strBase64: String
                            
                            if let url = toPass["url"] {
                                let nsurl: NSURL = NSURL(string: url)!
                                let imageData: NSData = NSData.init(contentsOf: nsurl as URL)!
                                
                                //This is pointless right now. Should probably take out.
                                self.currentUser = User(name: toPass["name"]!, email: toPass["email"]!, picture: imageData, facebook: true, uid: user!.uid)!
                                
                                //POPULATE curUser
                                curUser.email = self.currentUser!.email
                                curUser.image = UIImage(data: self.currentUser!.picture as Data)!
                                curUser.id = self.currentUser!.uid
                                curUser.name = self.currentUser!.name
                                
                                
                                
                            } else {
                                let deafulter = UIImagePNGRepresentation(#imageLiteral(resourceName: "defaultPhoto"))! as NSData
                                
                                self.currentUser = User(name: toPass["name"]!, email: toPass["email"]!, picture: deafulter , facebook: true, uid: user!.uid)!
                                
                                //Populate curUser
                                curUser.email = self.currentUser!.email
                                curUser.image = UIImage(data: self.currentUser!.picture as Data)!
                                curUser.id = self.currentUser!.uid
                                curUser.name = self.currentUser!.name
                                
                                
                            }
                            self.load()
                            self.currentUser!.addUser(){(succuess) -> Void in
                                self.performSegue(withIdentifier: "toGroupPrompt", sender: nil)
                                
                            }
                            
                            
                        })} else {
                        let currentUser = FIRAuth.auth()?.currentUser
                        
                        let userRef = FIRDatabase.database().reference().child("User").child((currentUser?.uid)!)
                        let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                        userRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
                            self.load()
                            if (!snapshot.exists() || (snapshot.value as! [String:AnyObject])["group"] as! String == "") {
                                //No, then go to groupprompt
                                self.performSegue(withIdentifier: "toGroupPrompt", sender: nil)
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
        }
    }

    public func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
    }
    
    
    //Function which fetches information from Facebook SDK
    func fetchProfile(_ completionHandler: @escaping ([String: String], NSError?) -> Void) {
        
        //Requesting email, name, and profile picture
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        var passOn = [String: String]()
        
        //Start information fetching
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start( completionHandler: { (connection, result, error) -> Void in
            //Handle error
            if error != nil {
                return
            }
            
            let result = result as? NSDictionary
            
            //Store the email, picture, and name as static variables
            if let email1 = result?["email"] as? String {
                passOn["email"] = String.init(stringInterpolationSegment: email1)
            } else {
                passOn["email"] = ""
            }
            if let picture = result?["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary,
                let url = data["url"] as? String {
                passOn["url"] = url
            } else {
                passOn["url"] = ""
            }
            if let firstName = result?["first_name"] as? String, let lastName = result?["last_name"] as? String {
                passOn["name"] = firstName + " " + lastName
            } else {
                passOn["name"] = ""
            }
            completionHandler(passOn, nil)
            
        })
        
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
    }
    
    // UI stuff
    func addBackground() {
        /*
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.image = UIImage(named: "loginBackground")
//        imageView.tintColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        imageView.image = imageView.image?.maskWithColor(color: UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0))
        self.view.addSubview(imageView)
        */
        
        let dynamicView=UIView(frame: self.view.bounds)
        dynamicView.backgroundColor=UIColor.clear
        
        let imageView=UIImageView(frame: self.view.bounds)
        imageView.image = UIImage(named: "loginBackground")
        dynamicView.addSubview(imageView)
        
        let tranpView=UIView(frame: self.view.bounds)
        tranpView.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        tranpView.backgroundColor = tranpView.backgroundColor!.withAlphaComponent(0.15)
        
        dynamicView.addSubview(tranpView)
        
        self.view.addSubview(dynamicView)
        
    }
    
    func addLogoLabel() {
        let screen = self.view.frame
        logoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        logoLabel.textColor = UIColor.white
        logoLabel.text = "HouseMate"
        //        logoLabel.font = UIFont.systemFontOfSize(30)
        logoLabel.font = UIFont(name: "Luna", size: 28)
        
        logoLabel.sizeToFit()
        logoLabel.center.x = self.view.center.x
        logoLabel.center.y = screen.height * 0.2
        self.view.addSubview(logoLabel)
    }
    
    
    func addFacebookLoginButton() {
        let screen = self.view.frame
        loginFacebookButton.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        self.loginFacebookButton.layer.cornerRadius = 5
        
        self.loginFacebookButton.center.x = self.view.center.x
        self.loginFacebookButton.center.y = screen.height * 0.7
        
        self.loginFacebookButton.titleLabel!.font =  UIFont(name: "Lato-Bold", size: 15)
        
        self.loginFacebookButton.readPermissions = ["public_profile", "email", "user_friends"]
        self.loginFacebookButton.delegate = self;
        self.view!.addSubview(self.loginFacebookButton)
        self.loginFacebookButton.isHidden = false
    }
    
    func addSignUpButton() {
        let screen = self.view.frame
        signUpButton = UIButton(frame: CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07))
        signUpButton.center.x = self.view.center.x
        signUpButton.center.y = screen.height * 0.78
        
        signUpButton.setTitle("Sign up with Email", for: UIControlState())
        signUpButton.setTitleColor(UIColor.white, for: UIControlState())
        signUpButton.titleLabel!.font =  UIFont(name: "Lato-Bold", size: 15)
        
        signUpButton.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        signUpButton.layer.cornerRadius = 5
        
        signUpButton.addTarget(self, action: #selector(signUp), for: UIControlEvents.touchUpInside)
        signUpButton.tag = 1
        
        self.view.addSubview(signUpButton)
        
    }
    
    func addLoginLabel() {
        let screen = self.view.frame

        let customString = NSMutableAttributedString(string: "Already have an account? Log In", attributes: [NSFontAttributeName:UIFont(name: "Lato-Regular", size: 15)!])
        customString.addAttribute(NSFontAttributeName, value: UIFont(name: "Lato-Bold", size: 15)!, range: NSRange(location:24,length:5))

        loginLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        loginLabel.textColor = UIColor.white
        loginLabel.attributedText = customString
        
        loginLabel.sizeToFit()
        loginLabel.center.x = self.view.center.x
        loginLabel.center.y = screen.height * 0.85
        
        self.view.addSubview(loginLabel)
        
        self.loginLabel.isUserInteractionEnabled = true
        let logInTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.logIn(recognizer:)))
        self.loginLabel.addGestureRecognizer(logInTapRecognizer)

    }
    
    func setSpinner() {
        loadingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        loadingSpinner.isHidden = true
        //        loadingSpinner.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        loadingSpinner.color = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
    }
    
    func load() {
        for view in self.view.subviews {
            if view != loadingSpinner {
                view.removeFromSuperview()
            }
        }
//        self.logoLabel.isHidden = true
//        self.usernameTextField.isHidden = true
//        self.passwordTextField.isHidden = true
//        self.signUpButton.isHidden = true
//        self.loginFacebookButton.isHidden = true
//        self.loginLabel.isHidden = true
        
        self.loadingSpinner.isHidden = false
        self.loadingSpinner.startAnimating()
    }
    
    func signUp(sender: UIButton) {
        self.performSegue(withIdentifier: "toSignUp", sender: nil)
    }
    
    
    func logIn(recognizer: UIGestureRecognizer) {
        self.performSegue(withIdentifier: "toLogIn", sender: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

