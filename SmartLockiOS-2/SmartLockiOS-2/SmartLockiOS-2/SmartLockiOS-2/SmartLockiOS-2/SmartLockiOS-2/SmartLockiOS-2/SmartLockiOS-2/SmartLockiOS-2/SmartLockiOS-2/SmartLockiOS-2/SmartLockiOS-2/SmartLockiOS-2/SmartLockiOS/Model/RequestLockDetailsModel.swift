//
//  RequestLockDetailsModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 19/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class RequestLockDetailsModel: NSObject {
    var id: String! // lock_id
    var name: String!
    var userId: String!
    var status: String!
    var lockVersion: String!
    var serialNumber: String!
}
