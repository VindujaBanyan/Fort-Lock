//
//  TabsCollectionViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 13/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class TabsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.iconLabel.font = UIFont.setRobotoRegular12FontForTitle
    }

}
