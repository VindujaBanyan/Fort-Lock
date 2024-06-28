//
//  AssignUserSubTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 20/09/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class AssignUserSubTableViewCell: UITableViewCell {

    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var viewButton:  UIButton?
    @IBOutlet weak var revokeButton: UIButton?
    @IBOutlet weak var revokeWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var scheduleAccessButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
