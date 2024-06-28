//
//  LeftViewTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 13/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class LeftViewTableViewCell: UITableViewCell {
    @IBOutlet weak var menuLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.menuLabel.font = UIFont.setRobotoRegular18FontForTitle
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
