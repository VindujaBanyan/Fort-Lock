//
//  LockHistoryTableViewCell.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/19/18.
//  Copyright © 2018 payoda. All rights reserved.
//
 
import UIKit

class LockHistoryTableViewCell: UITableViewCell {

    @IBOutlet var iconView:UIImageView!
    @IBOutlet var dateTimeLabel:UILabel!
    @IBOutlet var activityLabel:UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    
}
