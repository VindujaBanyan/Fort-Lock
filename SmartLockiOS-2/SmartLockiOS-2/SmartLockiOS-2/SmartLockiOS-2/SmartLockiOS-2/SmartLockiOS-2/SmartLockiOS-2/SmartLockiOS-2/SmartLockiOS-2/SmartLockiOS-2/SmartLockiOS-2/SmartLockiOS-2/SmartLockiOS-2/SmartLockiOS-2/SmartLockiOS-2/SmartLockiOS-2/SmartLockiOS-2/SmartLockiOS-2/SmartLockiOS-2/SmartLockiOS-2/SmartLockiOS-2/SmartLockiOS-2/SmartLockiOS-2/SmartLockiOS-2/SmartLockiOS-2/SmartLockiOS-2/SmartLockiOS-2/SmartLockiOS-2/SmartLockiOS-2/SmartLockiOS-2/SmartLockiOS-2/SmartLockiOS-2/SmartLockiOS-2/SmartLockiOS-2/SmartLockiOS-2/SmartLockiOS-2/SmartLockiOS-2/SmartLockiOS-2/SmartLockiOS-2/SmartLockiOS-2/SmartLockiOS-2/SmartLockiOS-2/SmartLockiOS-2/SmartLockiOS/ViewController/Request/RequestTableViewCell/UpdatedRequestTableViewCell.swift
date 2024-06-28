//
//  UpdatedRequestTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class UpdatedRequestTableViewCell: UITableViewCell {
    @IBOutlet var requestedUserNameLabel: UILabel!

    @IBOutlet var requestStatusLabel: UILabel!

    @IBOutlet var requestdescriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
