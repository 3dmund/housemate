//
//  InactiveTableViewCell.swift
//  Chores
//
//  Created by Edmund Tian on 12/20/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit

class InactiveTableViewCell: UITableViewCell {

    // Attributes
    var chore: Chore!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var choreLabel: UILabel!
    @IBOutlet weak var assignedLabel: UILabel!
    
    @IBAction func pushPressed(_ sender: UIButton) {
        chore.update(updatingCurrent: false)
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
        choreLabel.font = UIFont(name: "Lato-Medium", size: 22)
    }
    
    func setAssigned(assigned: String) {
        //        printFonts()
        var name = assigned
        // MARK: Change this later
        if assigned == "You" {
            name = "You're"
        }
        else {
            name = assigned.characters.split{$0 == " "}.map(String.init)[0]
            name.append("'s")
        }
        var text = name
        text.append(" next")
        let customString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName:UIFont(name: "Lato-Light", size: 15)!])
        customString.addAttribute(NSFontAttributeName, value: UIFont(name: "Lato-Medium", size: 15)!, range: NSRange(location:0,length:name.characters.count))
        self.assignedLabel.attributedText = customString
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
