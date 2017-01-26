//
//  ActiveTableViewCell.swift
//  Chores
//
//  Created by Edmund Tian on 12/20/16.
//  Copyright © 2016 Edmoneh. All rights reserved.
//

import UIKit

class ActiveTableViewCell: UITableViewCell {
    
    // Attributes
    var chore: Chore!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var choreLabel: UILabel!
    @IBOutlet weak var assignedLabel: UILabel!
    
    // Done with chore
    @IBAction func donePressed(_ sender: UIButton) {
        chore.update(updatingCurrent: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        choreLabel.font = UIFont(name: "Lato-Medium", size: 22)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
//        print("selected")
    }
    
    func setAssigned(assigned: String) {
//        printFonts()
        var name = assigned
        if assigned == "You" {
            name = "Your"
        }
        else {
            name = assigned.characters.split{$0 == " "}.map(String.init)[0]
            name.append("'s")
        }
        var text = name
        text.append(" turn")
        let customString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName:UIFont(name: "Lato-Light", size: 15)!])
        customString.addAttribute(NSFontAttributeName, value: UIFont(name: "Lato-Medium", size: 15)!, range: NSRange(location:0,length:name.characters.count))
        self.assignedLabel.attributedText = customString
    }

}
