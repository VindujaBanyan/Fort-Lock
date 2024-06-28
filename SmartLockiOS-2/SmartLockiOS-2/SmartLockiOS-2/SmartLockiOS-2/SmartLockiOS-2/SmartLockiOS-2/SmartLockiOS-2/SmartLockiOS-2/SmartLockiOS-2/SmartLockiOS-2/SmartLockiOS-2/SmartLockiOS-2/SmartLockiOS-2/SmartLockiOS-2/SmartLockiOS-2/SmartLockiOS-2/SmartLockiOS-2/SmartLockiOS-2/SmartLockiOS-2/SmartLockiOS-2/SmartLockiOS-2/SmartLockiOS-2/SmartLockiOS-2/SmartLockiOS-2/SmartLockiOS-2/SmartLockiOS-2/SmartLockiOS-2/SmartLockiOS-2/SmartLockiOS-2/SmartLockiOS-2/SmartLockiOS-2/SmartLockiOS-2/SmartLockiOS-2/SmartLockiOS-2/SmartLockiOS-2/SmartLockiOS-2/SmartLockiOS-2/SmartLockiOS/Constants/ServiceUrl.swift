//
//  ServiceUrl.swift
//  SmartLockiOS
//
//  Created by Sambath on 10/11/19.
//  Copyright © 2019 payoda. All rights reserved.
//

import Foundation

class ServiceUrl {
    
    var DOMAIN_URL: String = ""
    let VERSION =  "/api/web/v1/"
    static var BASE_URL: String = ""
    static var REDIRECTION_URL: String = ""
    
    //Choose the environment you want to publish
//    var currentEnvironment : Environment = Environment.UAT
    
    
     init() {
        let endpoint = Bundle.main.infoDictionary?["ENDPOINT_URL"] as! String
        DOMAIN_URL = endpoint
        ServiceUrl.BASE_URL = DOMAIN_URL + VERSION
        ServiceUrl.REDIRECTION_URL = DOMAIN_URL
        NSLog("BASE_URL->" + ServiceUrl.BASE_URL)
    }

    //Environment List
    enum Environment :String {
        case DEV
        case QA
        case UAT
        case PROD
        case FACTORY
    }

}
