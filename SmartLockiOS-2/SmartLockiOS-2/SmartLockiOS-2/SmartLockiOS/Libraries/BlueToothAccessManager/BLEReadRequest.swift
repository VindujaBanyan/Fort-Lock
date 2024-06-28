//
//  BLEReadRequest.swift
//  BluetoothAccess
//
//  Created by Dhilip on 6/17/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import Foundation
typealias BLERequestCompletionBlock = (_ isSuccess:Bool,_ response:String?,_ error:String?) -> Void
class BLERequest {
    let characteristic:LockCharacteristic
    let completionBlock:BLERequestCompletionBlock
    let isReadRequest:Bool


    init(characteristic:LockCharacteristic,isReadRequest:Bool,completion:@escaping BLERequestCompletionBlock) {
        self.characteristic = characteristic
        self.completionBlock = completion
        self.isReadRequest = isReadRequest
    }
}


class BLEOperation {

    static func writeOperation(data:Data,request:BLERequest,operation:String = "") -> BlockOperation{
        let writeOperation = BlockOperation {
            //print("writing " + operation)
            let status = BluetoothAccessManager.shared.write(data: data, request: request)
            BLELockAccessManager.shared.handle(write: status)
        }
        return writeOperation
    }

    static func readOperation(request:BLERequest,operation:String = "") -> BlockOperation{
        let readOperation = BlockOperation {
            print("reading  operation")
            BluetoothAccessManager.shared.readCharacteristic(request: request)
        }
        return readOperation
    }
}


