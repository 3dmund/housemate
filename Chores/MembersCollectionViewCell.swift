//
//  MembersCollectionViewCell.swift
//  Chores
//
//  Created by Edmund Tian on 12/22/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FirebaseAuth
import FirebaseDatabase



class MembersCollectionViewCell: UICollectionViewCell {
    
    // Attributes
    weak var delegate: CollectionViewCellDelegate?
    var user: CollectionViewUser!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    func setUI() {
        self.layer.cornerRadius = 5
        nameLabel.sizeToFit()
        self.backgroundColor = UIColor.white
    }
    
    // Actions
    @IBAction func deletePressed(_ sender: UIButton) {
        
        self.delegate?.showAlert(user: self.user)
        
    }
    
    
}
