//
//  AssignUserModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class AssignUserModel: NSObject {
    var name: String!
    var id: String!
    var lockId: String!
    var userId: String!
    var userType: String!
    var key: String!
    var slotNumber: String!
    var status: String!
    var userDetails: AssignUserDetailsModel!
    var requestDetails: AssignUsersRequestDetailsModel!
    var is_schedule_access: String!
    var schedule_date_from: String!
    var schedule_date_to: String!
    var schedule_time_from: String!
    var schedule_time_to: String!
}
