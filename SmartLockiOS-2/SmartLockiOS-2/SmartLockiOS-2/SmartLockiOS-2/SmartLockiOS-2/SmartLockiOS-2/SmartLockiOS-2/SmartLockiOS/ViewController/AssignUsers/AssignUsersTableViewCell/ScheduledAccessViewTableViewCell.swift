//
//  ScheduledAccessViewTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 05/12/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class ScheduledAccessViewTableViewCell: UITableViewCell {

    @IBOutlet weak var detailsLabel: UILabel?
    @IBOutlet weak var iconImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
