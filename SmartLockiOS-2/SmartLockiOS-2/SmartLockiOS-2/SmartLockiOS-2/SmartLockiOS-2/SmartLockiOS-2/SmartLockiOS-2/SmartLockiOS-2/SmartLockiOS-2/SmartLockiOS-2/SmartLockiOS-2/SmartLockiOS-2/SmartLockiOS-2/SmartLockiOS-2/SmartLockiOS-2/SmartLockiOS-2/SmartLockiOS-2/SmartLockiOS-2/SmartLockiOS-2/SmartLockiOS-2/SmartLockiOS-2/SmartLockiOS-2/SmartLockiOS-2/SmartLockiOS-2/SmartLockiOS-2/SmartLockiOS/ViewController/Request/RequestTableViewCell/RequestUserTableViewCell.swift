//
//  RequestUserTableViewCell.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

protocol RequestUsersProtocol: class {
    func updateRequestStatus(_ sender: UIButton, _ requestStatus: String)
}

class RequestUserTableViewCell: UITableViewCell {
    var requestUsersDelegate: RequestUsersProtocol?
    
    @IBOutlet var requesterNameLabel: UILabel!
    @IBOutlet var requestDescriptionLabel: UILabel!
    
    @IBOutlet var requestRejectButton: UIButton!
    @IBOutlet var requestAcceptButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.requestRejectButton.layer.cornerRadius = 10.0
        self.requestRejectButton.layer.masksToBounds = true
        self.requestRejectButton.layer.borderColor = REJECT_COLOR.cgColor
        self.requestRejectButton.layer.borderWidth = 1.0
        self.requestRejectButton.setTitleColor(REJECT_COLOR, for: .normal)
        
        self.requestAcceptButton.layer.cornerRadius = 10.0
        self.requestAcceptButton.layer.masksToBounds = true
        self.requestAcceptButton.backgroundColor = ACCEPT_COLOR
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onTapRequestAcceptButton(_ sender: UIButton) {
        self.requestUsersDelegate?.updateRequestStatus(sender, "1")
    }
    
    @IBAction func onTapRequestRejectButton(_ sender: UIButton) {
        self.requestUsersDelegate?.updateRequestStatus(sender, "2")
    }
}
