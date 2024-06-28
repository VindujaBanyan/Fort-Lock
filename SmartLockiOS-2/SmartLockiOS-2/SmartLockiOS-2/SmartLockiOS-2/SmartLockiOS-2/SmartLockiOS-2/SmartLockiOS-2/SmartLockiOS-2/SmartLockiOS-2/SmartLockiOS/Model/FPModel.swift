//
//  FPModel.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/7/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class FPModel: NSObject {
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
    var registrationDetails: RegistrationDetailsModel! // -- need to check for values
    var registration_id: String!
//    var parent_user_id: String!
    // Custom params
    var isGuestUser: Bool!
    var numberOfKeysAssigned: Int!
    
}

/*
▿ Optional<JSON>
  ▿ some : {
  "status" : "success",
  "data" : [
    {
      "id" : "11695",
      "is_schedule_access" : null,
      "lock_id" : "453",
      "schedule_date_from" : null,
      "key" : "[\"2\"]",
      "user_id" : null,
      "userDetails" : null,
      "parent_user_id" : null,
      "status" : "2",
      "requestDetails" : null,
      "slot_number" : "0",
      "registrationDetails" : {
        "user_id" : null,
        "id" : "449",
        "name" : "TestE"
      },
      "name" : "Fingerprint",
      "schedule_date_to" : null,
      "schedule_time_to" : null,
      "registration_id" : "449",
      "user_type" : "Fingerprint",
      "schedule_time_from" : null
    }
  ],
  "message" : "Lock listed successfully."
}

*/
