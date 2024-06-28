//
//  LockListTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 11/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class LockListTableViewCell: UITableViewCell {

    @IBOutlet weak var lockNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
