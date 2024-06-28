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
    
   // var lockDetailsViewController: LockDetailsViewController
        
//        init(lockDetailsViewController: LockDetailsViewController) {
//            self.lockDetailsViewController = lockDetailsViewController
//        }
    
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
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        print("Branding bundleIdentifier = \(bundleIdentifier)")
        let headers: HTTPHeaders = [/*"Authorization": authToken, "Content-Type": "application/json; charset=utf-8",*/ "bundle-id":bundleIdentifier]
        print("Branding headers = \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result, error in
            if result {
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        switch response.result {
                        case .success(let value):
                                _ = JSON(value)
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
    func configureHomeWiFiMqtt(url: String, wifiDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = wifiDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8","bundle-id":"com.tbi.fort.nova","Authorization":authToken]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.configWiFiMqtt.rawValue
        print("home wifi headers\(headers)")


        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        print("Response is\(getResponse) ")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
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
        if let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) {
            authToken = "Bearer " + authTokenValue
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
            validateSSLPinning(url: URL(string: url)!) { result,error  in
                if(result){
                    AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                        .responseJSON { response in
                            
                            let getResponse = self.handleResponse(responseObj: response)
                            callback(getResponse.json, getResponse.error)
                        }
                }
                else {
                    callback(nil, error)
                }
            }
        }
    }
    
    func remoteActivityServiceCall(url: String, tokenDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = tokenDetails
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
//    func loginServiceCall(url: String, email: String, password: String, callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
//        let parameters: Parameters = [
//            "email": email,
//            "password": password
//        ]
//
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "bundle_id": Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
//        ]
//
//        validateSSLPinning(url: URL(string: url)!) { result, error in
//            if result {
//                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
//                    .responseJSON { response in
//                        let getResponse = self.handleResponse(responseObj: response)
//                        callback(getResponse.json, getResponse.error)
//                    }
//            } else {
//                callback(nil, error)
//            }
//        }
//    }
//    func loginServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
//        let parameters: Parameters = userDetails
//        var headers: HTTPHeaders = ["Content-Type": "application/json; charset=utf-8"]
//
//        if let bundleIdentifier = Bundle.main.bundleIdentifier {
//            print("Bundle Identifier: \(bundleIdentifier)")
//            headers["bundle_id"] = bundleIdentifier
//        } else {
//            print("Unable to retrieve bundle identifier")
//        }
//
//        print("Headers: \(headers)")
//
//        validateSSLPinning(url: URL(string: url)!) { result, error in
//            if result {
//                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
//                    .responseDecodable(of: SignInModel.self) { response in
//                        switch response.result {
//                        case .success(let value):
//                            // Handle successful decoding
//                            print("Decoded value: \(value)")
//                            callback(value, nil)
//
//                        case .failure(let error):
//                            // Handle decoding failure or other errors
//                            print("Error: \(error)")
//                            callback(nil, error as NSError)
//                        }
//                    }
//            } else {
//                callback(nil, error)
//            }
//        }
//    }


    func loginServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
//        var headers:HTTPHeaders = ["Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        var headers: HTTPHeaders = ["Content-Type": "application/json; charset=utf-8"]

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            print("Bundle Identifier: \(bundleIdentifier)")
            headers["bundle-id"] = bundleIdentifier
        } else {
            print("Unable to retrieve bundle identifier")
        }

        print("Headers: \(headers)")


        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        let getResponse = self.handleResponse(responseObj: response)
                        print("Response is\(getResponse) ")
                        callback(getResponse.json, getResponse.error)
                    }
            }else {
                callback(nil, error)
            }
        }
    }
    
    func signUpServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8"]
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            print("Bundle Identifier: \(bundleIdentifier)")
            headers["bundle-id"] = bundleIdentifier
        } else {
            print("Unable to retrieve bundle identifier")
        }

        
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        let getResponse = self.handleResponse(responseObj: response)
                        callback(getResponse.json, getResponse.error)
                    }
//                    .responseJSON { response in
//                        switch response.result {
//                        case .success(let value):
//                            // Handle success
//                                callback(value as? JSON, nil)
//                        case .failure(let error):
//                            // Handle failure
//                            print("Error: \(error.localizedDescription)")
//                            callback(nil, error as NSError)
//                        }
//                    }

            }else {
                callback(nil, error)
            }
        }
        
    }
    
    func forgotPasswordServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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

        if let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) {
            authToken = "Bearer " + authTokenValue

            if let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
                let headers: HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : bundleIdentifier]

                validateSSLPinning(url: URL(string: url)!) { result, error in
                    if result {
                        AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                            .responseJSON { response in
                                let getResponse = self.handleResponse(responseObj: response)
                                callback(getResponse.json, getResponse.error)
                            }
                    } else {
                        callback(nil, error)
                    }
                }
            } else {
                // Handle the case where bundle identifier is nil
            }
        } else {
            // Handle the case where authTokenValue is nil
        }
    }

    
//    func getLockListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
//        let parameters: Parameters = userDetails
//        var authToken = ""
//        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
//        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
//        authToken = "Bearer " + authTokenValue!
//        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
////        print("------------------------------------");
////        print("url ===> \(url)")
////        print("parameters ===> \(parameters)")
////        print("headers ===> \(headers)")
////        print("------ getLockListServiceCall request Time stamp --- \(NSDate().timeIntervalSince1970)")
//        validateSSLPinning(url: URL(string: url)!) { result,error  in
//            if(result){
//                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
//                    .responseJSON { response in
//                        
//                        //print("------ getLockListServiceCall request Time stamp --- \(NSDate().timeIntervalSince1970)")
//                        //                print("response ===> \(response)")
//                        let getResponse = self.handleResponse(responseObj: response)
//                        callback(getResponse.json, getResponse.error)
//                    }
//            }else {
//                callback(nil, error)
//            }
//        }
//        
//    }
    
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        print("URL ==> \(url)")
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
        print("URL for activity ==> \(url)")
        print("parameters for activity ==> \(parameters)")
        print("authTokenValue for activity ==> \(authTokenValue)")
        print("headers for activity ==> \(headers)")
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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

        if let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) {
            authToken = "Bearer " + authTokenValue

            if let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
                print("@@bundle ID= \(bundleIdentifier)")
                let headers: HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : bundleIdentifier]
                print("Config headers: \(headers)")
                validateSSLPinning(url: URL(string: url)!) { result, error in
                    if result {
                        AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                            .responseJSON { response in
                                let getResponse = self.handleResponse(responseObj: response)
                                print("config Response\(getResponse)")
                                callback(getResponse.json, getResponse.error)
                            }
                    } else {
                        callback(nil, error)
                    }
                }
            } else {
                // Handle the case where bundle identifier is nil
            }
        } else {
            // Handle the case where authTokenValue is nil
        }
    }

//    func getServerDateAndTimeServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
//        var authToken = ""
//        if let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) {
//            authToken = "Bearer " + authTokenValue
//        } else {
//            // Handle the case where authTokenValue is nil
//        }
//        if let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
//            let headers: HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : bundleIdentifier]
//        } else {
//            // Handle the case where bundle identifier is nil
//        }
//
//        
//        //print("URL ==> \(url)")
//        //        //print("parameters ==> \(parameters)")
//        //print("authTokenValue ==> \(String(describing: authTokenValue))")
//        //print("headers ==> \(headers)")
//        validateSSLPinning(url: URL(string: url)!) { result,error  in
//            if(result){
//                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
//                    .responseJSON { response in
//                        
//                        //print("response ==> \(response)")
//                        
//                        let getResponse = self.handleResponse(responseObj: response)
//                        callback(getResponse.json, getResponse.error)
//                    }
//            }else {
//                callback(nil, error)
//            }
//        }
//        
//    }
    
    
    
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
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
        var jsonObject = JSON(responseObj.data as Any)
        print("Response Status Code: \(responseObj.response?.statusCode ?? -1)")
        
       // print("######\(jsonObject)")
        if let responseData = responseObj.data {
            print("Response Data: \(String(data: responseData, encoding: .utf8) ?? "")")
//            if let enablePassageValue = jsonObject["enable_passage"].string {
//                        if LockDetailsViewController().passageModeSwitch.isOn {
//                            // If passage mode is enabled, set "enable_passage" to "1"
//                            jsonObject["enable_passage"] = JSON("1")
//                        }
//                    }
                    
                    // Return the modified JSON response
                    return (jsonObject, nil)
        }

            
            
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        print("Version Headers : \(headers)")
        validateSSLPinning(url: URL(string: url)!) { result,error  in
            if(result){
                AlamofireAppManager.shared.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    .responseJSON { response in
                        
                        print("response ==> \(response)")
                        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json; charset=utf-8", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
       print("URL ==> \(url)")
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
       print("URL ==> \(url)")
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
    
    func  updatePinViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        let parameters: Parameters = userDetails
        var authToken = ""
        //        authToken = "Bearer " + "uUgMFSVbj_J72zztxgecDTFvabOqNHO8"
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
        let headers:HTTPHeaders = ["Authorization": authToken, "Content-Type": "application/json", "bundle-id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        
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
