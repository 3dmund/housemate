//
//  GroupPrompt.swift
//  Split
//
//  Created by Timothy Chodins on 8/15/16.
//  Copyright © 2016 Tarun Khasnavis. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

func getPassCode() -> String{
    var passCode = ""
    passCode = String(arc4random_uniform(999999) + 1)
    while passCode.characters.count < 6 {
        passCode.insert("0", at: passCode.startIndex)
    }
    print(passCode)
    
    return passCode
}

class GroupPromptViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    var text = String()
    var uid = String()
    var screen: CGRect = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.uid = (FIRAuth.auth()?.currentUser?.uid)!
        print("did load and id is: " + self.uid)
        
        screen = self.view.frame
        
        setJoinButton()
        setCreateButton()
        
    }
    
    func setCreateButton() {
        self.createButton.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        self.createButton.layer.cornerRadius = 10
        self.createButton.titleLabel!.font =  UIFont(name: "Lato-Bold", size: 20)
        
        createButton.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        createButton.center.x = self.view.center.x
        createButton.center.y = screen.height * 0.46
    }
    
    func setJoinButton() {
        self.joinButton.setTitleColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0), for: .normal)
        self.joinButton.layer.borderWidth = 1
        self.joinButton.layer.borderColor = UIColor(red:0.80, green:0.80, blue:0.80, alpha:1.0).cgColor
        self.joinButton.layer.cornerRadius = 10
        self.joinButton.titleLabel!.font =  UIFont(name: "Lato-Regular", size: 20)
        
        joinButton.frame = CGRect(x: 0, y: 0, width: screen.width * 0.75, height: screen.height * 0.07)
        joinButton.center.x = self.view.center.x
        joinButton.center.y = screen.height * 0.54
    }
    
}
