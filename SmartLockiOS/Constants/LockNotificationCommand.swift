//
//  LockNotificationCommand.swift
//  SmartLockiOS
//
//  Created by mohamedshah on 25/05/22.
//  Copyright © 2022 payoda. All rights reserved.
//

import Foundation

enum LockNotificationCommand: String {
    case ENGAGE
    case USER_REVOKE
    case MASTER_REVOKE
    case FP_DELETE
    case RFID_DELETE
    case FP_ON
    case FP_OFF
    case PIN_ON
    case PIN_OFF
    case PIN_REWRITE
    case OTP_REWRITE
    case OWNER_TRANSFER
    case PASSAGE_MODE_ENABLED
    case PASSAGE_MODE_DISABLED
}
