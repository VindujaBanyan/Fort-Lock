//
//  SignInModel.swift
//  Fort
//
//  Created by The Banyan Infotech on 31/01/24.
//  Copyright © 2024 payoda. All rights reserved.
//

import Foundation

struct SignInModel : Codable {
   var deviceId: String
      var deviceToken: String
      var deviceType: String
      var password: String
      var email: String
    var code: Int
}
