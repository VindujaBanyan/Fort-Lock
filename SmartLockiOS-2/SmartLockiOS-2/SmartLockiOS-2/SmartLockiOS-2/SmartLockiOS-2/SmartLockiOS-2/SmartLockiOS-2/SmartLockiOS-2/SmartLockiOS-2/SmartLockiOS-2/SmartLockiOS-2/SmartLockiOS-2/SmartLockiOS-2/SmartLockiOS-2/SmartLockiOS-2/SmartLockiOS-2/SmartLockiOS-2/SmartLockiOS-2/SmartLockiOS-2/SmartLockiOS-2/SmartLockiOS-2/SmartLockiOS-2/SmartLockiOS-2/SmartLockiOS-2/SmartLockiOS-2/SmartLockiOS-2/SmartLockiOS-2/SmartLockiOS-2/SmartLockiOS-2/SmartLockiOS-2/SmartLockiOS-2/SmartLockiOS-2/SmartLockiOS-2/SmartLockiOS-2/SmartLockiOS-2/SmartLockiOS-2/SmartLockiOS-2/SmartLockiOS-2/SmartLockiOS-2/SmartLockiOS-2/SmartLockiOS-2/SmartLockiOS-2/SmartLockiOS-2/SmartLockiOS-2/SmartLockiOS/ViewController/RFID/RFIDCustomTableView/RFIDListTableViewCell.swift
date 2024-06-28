//
//  RFIDListTableViewCell.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/3/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class RFIDListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addOrRevokeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
