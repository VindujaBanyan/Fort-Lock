//
//  FPListTableViewCell.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/7/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class FPListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyCountLabel: UILabel!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var revokeButton: UIButton!
    
    @IBOutlet weak var editButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButtonLeadingConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
