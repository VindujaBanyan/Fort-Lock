//
//  NetworkManager.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 29/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
//import Alamofire
//import SwiftyJSON
//import TrustKit
import SlideMenuControllerSwift
import Alamofire
import SwiftyJSON
import TrustKit

enum WebServiceError {
    static let errorMessage = "ErrorMessage"
    static let developerMessage = "DeveloperMessage"
    static let responseStatus = "ResponseStatus"
    static let errorCode = "ErrorCode"
}

struct AlamofireAppManager {
    
    static let shared: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 500//120//60
        let sessionManager = Session(configuration: configuration)
        return sessionManager
    }()
}


class NetworkManager: NSObject, URLSessionDelegate {
    
    lazy var session: URLSession = {
        URLSession(configuration: URLSessionConfiguration.ephemeral,
                   delegate: self,
                   delegateQueue: OperationQueue.main)
    }()
        
    // MARK: TrustKit Pinning Reference
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Call into TrustKit here to do pinning validation
        if TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler) == false {
            // TrustKit did not handle this challenge: perhaps it was not for server trust
            // or the domain was not pinned. Fall back to the default behavior
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func validateSSLPinning(url: URL, callback: @escaping (_ result: Bool, _ error: NSError?)-> Void){
        // Load a URL with a good pinning configuration
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard error == nil else {
                let errorStr = INTERNET_CONNECTION_VALIDATION
                let error = self?.makeErrorResponse(errorMessage: errorStr, errorCode: 0)
                callback(false, error)
                return
            }
            callback(true, nil)
        }
        
        task.resume()
    }
    
    

    func brandingServiceCall(url: String, callback: @escaping (_ json: JSON?, _ error: AFError?) -> Void) {
        let headers: HTTPHeaders = ["Content-Type": "application/json", "bundle_id": Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]

        validateSSLPinning(url: URL(string: url)!) { result, error in
            if result {
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            let jsonObject = JSON(value)
                            let getResponse = self.handleResponse(responseObj: response)
                                callback(getResponse.json, getResponse.error as? AFError)
                        case .failure(let error):
                            callback(nil, error)
                        }
                    }
            } else {
                callback(nil, error as? AFError)
            }
        }
    }


//    func brandingServiceCall(url: String, callback: @escaping (_ json: JSON?, _ error: AFError?) -> Void) {
//        let headers: HTTPHeaders = ["Content-Type": "application/json", "bundle_id": Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
//
//        validateSSLPinning(url: URL(string: url)!) { result, error in
//            if result {
//                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
//                    .responseJSON { response in
//                        let getResponse = self.handleResponse(responseObj: response)
//                        callback(getResponse.json, getResponse.error)
//                    }
//            } else {
//                callback(nil, error)
//            }
//        }
//    }

    
    
//    func brandingServiceCall(url: String, callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
//        let headerDictionary = ["Content-Type": "application/json", "bundle_id": Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
//
//        validateSSLPinning(url: URL(string: url)!) { result, error in
//            if result {
//                // Create HTTPHeaders instance from the dictionary
//                let headers = HTTPHeaders(headerDictionary)
//
//                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
//                    .responseJSON { response in
//                        let getResponse = self.handleResponse(responseObj: response)
//                        callback(getResponse.json, getResponse.error)
//                    }
//            } else {
//                callback(nil, error)
//            }
//        }
//    }
    
    
    
    
    
    
    
    
    
    func updateDeviceTokenServiceCall(url: String, tokenDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = tokenDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
    }
    
    func loginServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
    }
    
    func signUpServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func forgotPasswordServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Profile
    
    func getProfileDetailsServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updateProfileDetailsServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Lock
    
    func getLockListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
//        print("------------------------------------");
//        print("url ===> \(url)")
//        print("parameters ===> \(parameters)")
//        print("headers ===> \(headers)")
//        print("------ getLockListServiceCall request Time stamp --- \(NSDate().timeIntervalSince1970)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("------ getLockListServiceCall request Time stamp --- \(NSDate().timeIntervalSince1970)")
                        //                print("response ===> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func addLockDetailsServiceCall(url: String, userDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updateLockDetailsServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Request List
    
    func getRequestListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Assign User
    
    func getLockUsersListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
//        print("------------------------------------");
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
//        print("------ getLockUsersListServiceCall request Time stamp --- \(NSDate().timeIntervalSince1970)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        print("------ getLockUsersListServiceCall response Time stamp --- \(NSDate().timeIntervalSince1970)")
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
        
    }
    
    func createRequestUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updateRequestUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func revokeRequestUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                        
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Schedule Access
    
    func createOrUpdateScheduleAccessServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Finger print user privilege Access
    
    func updateFingerPrintUserPrivilegeServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Update Transfer Owner request
    
    func updateTransferOwnerRequestUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("TS response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Withdraw Transfer Owner request
    
    func withdrawTransferOwnerRequestUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("TS response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Notification List1
    
    func getNotificatioListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    
    // MARK: - Notification List1
    
    func getActivityListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func getActivityNotificationListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    //MARK: - GETTING SERVER DATE & TIME
    func getServerDateAndTimeServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(String(describing: authTokenValue))")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    
    
    func postActivityLogs(url:String,userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func postBatteryUpdate(url:String,userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        //print("response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Logout
    
    func logout(url:String,userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - DeleteAccount
    
    func deleteAccount(url:String,userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - RFID
    
    func getRFIDListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Finger Print
    
    func getFPListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func getExistingLockUserServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func createFingerPrintServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                        
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updateFingerPrintServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                        
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func editUserNameServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        //print("URL ==> \(url)")
        //print("parameters ==> \(parameters)")
        //print("authTokenValue ==> \(authTokenValue)")
        //print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                        
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MARK: - Response handler
    
    func handleResponse(responseObj: AFDataResponse<Any>) -> (json: JSON?, error: NSError?) {
        //        let responseUrl = responseObj.request
        //        let responseValue = responseObj.result.value
        let jsonObject = JSON(responseObj.data as Any)
        //let responseError = responseObj.result.error
        
        var errorMessage: String = ""
//        print("responseObj.response?.statusCode ===> \(responseObj.response?.statusCode)")
//        print("responseObj.request?.url ===>> \(String(describing: responseObj.request?.url))")
//        print("responseObj.response?.statusCode ==> \(responseObj.response?.statusCode)")
        
        // Success case - Response is 200 and no error in JSON
        guard responseObj.response?.statusCode != 200 else {
            return (json: jsonObject, error:nil)
        }
        
        if responseObj.data != nil{
            let errorString = String(data: responseObj.data!, encoding: .utf8)
            if errorString != nil{
                //print("error \(errorString)")
            }
        }
        else{
            //print("response obj is nil")
        }
        if case let .failure(afError) = responseObj.result {
            let code = afError as NSError
            let statusCode = code.code

            if statusCode == -1009 {
                errorMessage = INTERNET_CONNECTION_VALIDATION
            } else if statusCode == -1009 {
                errorMessage = "The request timed out"
            }
        

            
            /*
             
             400 - Bad request (On validation failure)
             401 - Unauthorized access (When an unknown user access the application)
             403 - Forbidden (When a known user access the unassigned functionality)
             
             */
        }
        
        if errorMessage != "" {
            let error = self.makeErrorResponse(errorMessage: errorMessage, errorCode: -1009)
            return (json: nil, error: error)
        }
        
        if jsonObject["status"].string?.lowercased() == "failure" {
            let errorMessage = jsonObject["message"].string
            let error = self.makeErrorResponse(errorMessage: errorMessage!, errorCode: 0)
            return (json: nil, error: error)
        }
        
        // Unknown Error
        
        let errorStr = "Server Error. Please try again later"
        let error = self.makeErrorResponse(errorMessage: errorStr, errorCode: 0)
        return (json: nil, error: error)
        
        /*
         let errorStr = (responseObj.request?.url?.absoluteString ?? "") + "Server Error. Please try again later"
         let error = self.makeErrorResponse(errorMessage: errorStr, errorCode: 0)
         
         //        let error = self.makeErrorResponse(errorMessage: "Server Error. Please try again later", errorCode: 0)
         return (json: nil, error: error)
         */
    }
    
    func makeErrorResponse(errorMessage: String, errorCode: Int = 0) -> NSError {
        var errorResponse = Dictionary<String, Any>()
        errorResponse[WebServiceError.errorMessage] = errorMessage
        errorResponse[WebServiceError.developerMessage] = errorMessage
        errorResponse[WebServiceError.responseStatus] = true
        errorResponse[WebServiceError.errorCode] = errorCode
        let error = NSError(domain: "Error", code: -1009, userInfo: errorResponse)
        
        return error
    }
    
    func addDigiPinsPrintServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: userDetails, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                        
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    
    func getDigiPinListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ data : Data,_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(response.data!,getResponse.json, getResponse.error)
                    }
            }else {
                callback(Data(), nil, error)
            }
        }
        
    }
    
    func getOTPListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ data : Data,_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        //print("response ==> \(getResponse.json)")
                        callback(response.data!,getResponse.json, getResponse.error)
                    }
            }else {
                callback(Data(), nil, error)
            }
        }
        
    }
    func getVersionConfigurationServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        //print("response ==> \(response)")
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    // MQTT
    func addLockViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = lockDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func engageLockViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = lockDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func revokeUserViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = lockDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func revokeFingerprintViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func revokeRfidViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
        
    }
    
    func manageFingerprintViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func managePinViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updatePinViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func updateOtpViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func acceptTransferOwnerViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
//        print("URL ==> \(url)")
//        print("parameters ==> \(parameters)")
//        print("authTokenValue ==> \(authTokenValue)")
//        print("headers ==> \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
                    .responseJSON { response in
                        //                print("ADD lock response ==> \(response)")
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
        
    }
    
    
}
extension Request {
    public func debugLog() -> Self {
#if DEBUG
        debugPrint(self)
#endif
        return self
    }
}
