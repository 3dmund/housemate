//
//  CollectionViewCell.swift
//  Split
//
//  Created by Timothy Chodins on 8/19/16.
//  Copyright © 2016 Tarun Khasnavis. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    // Attributes

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var selectedView: UIView!
    
    
    var user: CollectionViewUser!
    
    func setUI() {
        self.layer.cornerRadius = 5
        nameLabel.sizeToFit()
        selectedView.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        self.backgroundColor = UIColor.white
    }
    
    func select() {
        selectedView.isHidden = false
    }
    
    func deselect() {
        selectedView.isHidden = true
    }
    
    func setSize(screenWidth: CGFloat) {
        print("setting size")
        let cellsAcross: CGFloat = 3
        let spaceBetweenCells: CGFloat = 10
//        let dim = (collectionView.bounds.width - (cellsAcross - 1) * spaceBetweenCells) / cellsAcross
        let dim = (screenWidth - 40) / 3
        self.frame.size = CGSize(width: dim, height: dim)
    }
    

}
