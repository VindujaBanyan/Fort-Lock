//
//  RFIDModel.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/6/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class RFIDModel: NSObject {
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
//    var registrationDetails: String! // -- need to check for values
//    var registration_id: String!
//    var parent_user_id: String!
}


/*
▿ Optional<JSON>
  ▿ some : {
  "status" : "success",
  "data" : [
    {
      "is_schedule_access" : null,
      "userDetails" : null,
      "schedule_time_from" : null,
      "registrationDetails" : null,
      "schedule_date_to" : null,
      "name" : "RFID 1",
      "registration_id" : null,
      "requestDetails" : null,
      "parent_user_id" : null,
      "key" : "0",
      "status" : "2",
      "user_type" : "RFID",
      "lock_id" : "453",
      "schedule_time_to" : null,
      "user_id" : null,
      "id" : "11692",
      "slot_number" : "0",
      "schedule_date_from" : null
    },
    {
      "is_schedule_access" : "0",
      "userDetails" : null,
      "schedule_time_from" : null,
      "registrationDetails" : null,
      "schedule_date_to" : null,
      "name" : "RFID 2",
      "registration_id" : null,
      "requestDetails" : null,
      "parent_user_id" : null,
      "key" : "00000000",
      "status" : "1",
      "user_type" : "RFID",
      "lock_id" : "453",
      "schedule_time_to" : null,
      "user_id" : null,
      "id" : "11693",
      "slot_number" : "1",
      "schedule_date_from" : null
    },
    {
      "is_schedule_access" : "0",
      "userDetails" : null,
      "schedule_time_from" : null,
      "registrationDetails" : null,
      "schedule_date_to" : null,
      "name" : "RFID 3",
      "registration_id" : null,
      "requestDetails" : null,
      "parent_user_id" : null,
      "key" : "00000000",
      "status" : "1",
      "user_type" : "RFID",
      "lock_id" : "453",
      "schedule_time_to" : null,
      "user_id" : null,
      "id" : "11694",
      "slot_number" : "2",
      "schedule_date_from" : null
    }
  ],
  "message" : "Lock listed successfully."
}
*/
