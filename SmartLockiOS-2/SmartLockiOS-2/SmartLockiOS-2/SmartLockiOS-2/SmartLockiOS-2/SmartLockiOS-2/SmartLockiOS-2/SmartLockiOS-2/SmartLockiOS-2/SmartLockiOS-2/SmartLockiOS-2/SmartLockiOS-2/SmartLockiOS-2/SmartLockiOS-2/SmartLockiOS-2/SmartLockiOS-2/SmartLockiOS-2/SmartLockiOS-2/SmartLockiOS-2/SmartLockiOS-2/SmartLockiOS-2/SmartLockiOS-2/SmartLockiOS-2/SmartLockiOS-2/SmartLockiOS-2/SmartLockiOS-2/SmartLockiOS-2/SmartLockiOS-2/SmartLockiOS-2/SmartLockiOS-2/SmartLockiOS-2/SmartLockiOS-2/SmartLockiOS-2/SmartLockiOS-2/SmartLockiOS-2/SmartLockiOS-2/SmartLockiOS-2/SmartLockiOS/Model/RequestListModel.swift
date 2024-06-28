//
//  RequestListModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class RequestListModel: NSObject {
    var requestId: String!
    var lockId: String!
    var status: String!
    var requestTo: String!
    var requestBy: String!
    var keyId: String!
    var lockDetails: RequestLockDetailsModel!
    var keyDetails: RequestKeyDetailsModel!
    var requestFromUserDetails: AssignUserDetailsModel!
    var requestToUserDetails: AssignUserDetailsModel!
}
