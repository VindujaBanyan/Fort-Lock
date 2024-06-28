//
//  ProfileTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 01/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dummyLabel: UILabel!
    @IBOutlet weak var countryCodeView: UIView!
    @IBOutlet weak var countryCodeButton: UIButton!

    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.updateTextFont()
    }

    func updateTextFont() {
        self.placeholderLabel.font = UIFont.setRobotoRegular15FontForTitle
        self.detailLabel.font = UIFont.setRobotoRegular18FontForTitle
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
