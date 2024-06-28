//
//  DecodeObjects.swift
//  SmartLockiOS
//
//  Created by Kishore Prabhu Radhakrishnan on 09/04/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit

class DecodeDataClass: NSObject {

    
    
     func encodeLockOwnerToJson(param:[LockOwnerDetailsModel])->String{

         //encode

         let jsonEncoder = JSONEncoder()
         
         
         let jsonData = try! jsonEncoder.encode(param)


         let json = String(data: jsonData, encoding: String.Encoding.utf8)

     

         return json!



     }
     
    
    
    
     func encodeUserRoleToJson(param:[UserLockRoleDetails])->String{

         //encode

         let jsonEncoder = JSONEncoder()
         
         
         let jsonData = try! jsonEncoder.encode(param)


         let json = String(data: jsonData, encoding: String.Encoding.utf8)

         return json!



     }
     
    
    func decodeUserRole(jsonData:String)->[UserLockRoleDetails]{
        
        
        //decode

        let jsonDecoder = JSONDecoder()
        let jsonData2 = jsonData.data(using: String.Encoding.utf8)
        let obj = try! jsonDecoder.decode([UserLockRoleDetails].self, from: jsonData2!)
        return obj
        
    }
    
    
    func decodeLockOwner(jsonData:String)->[LockOwnerDetailsModel]{
        
        //decode

        let jsonDecoder = JSONDecoder()
        let jsonData2 = jsonData.data(using: String.Encoding.utf8)
        let obj = try! jsonDecoder.decode([LockOwnerDetailsModel].self, from: jsonData2!)
        return obj
        
    }
    
    
}
