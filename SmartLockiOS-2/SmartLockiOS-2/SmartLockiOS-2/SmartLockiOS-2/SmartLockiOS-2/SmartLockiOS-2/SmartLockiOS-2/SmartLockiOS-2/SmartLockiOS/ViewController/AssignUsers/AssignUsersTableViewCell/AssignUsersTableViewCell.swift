//
//  AssignUsersTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

protocol AssignUsersProtocol: class {
    func updateAssignUserStatus(_ sender: UIButton)
}

class AssignUsersTableViewCell: UITableViewCell {
    var delegate: AssignUsersProtocol?

    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var assignUserButton: UIButton!

    @IBOutlet weak var expandCollapseLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var expandCollapseLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton?
    @IBOutlet weak var infoButtonWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var scheduleAccessButton: UIButton?
    
    @IBOutlet weak var fpPrivilegeButton: UIButton!
    @IBOutlet weak var fpPrivilegeButtonWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expandCollapseLabel.layer.cornerRadius = 15.0
        expandCollapseLabel.layer.borderWidth = 1.0
        expandCollapseLabel.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func onTapAssignUserButton(_ sender: UIButton) {
        delegate?.updateAssignUserStatus(sender)
    }
}
