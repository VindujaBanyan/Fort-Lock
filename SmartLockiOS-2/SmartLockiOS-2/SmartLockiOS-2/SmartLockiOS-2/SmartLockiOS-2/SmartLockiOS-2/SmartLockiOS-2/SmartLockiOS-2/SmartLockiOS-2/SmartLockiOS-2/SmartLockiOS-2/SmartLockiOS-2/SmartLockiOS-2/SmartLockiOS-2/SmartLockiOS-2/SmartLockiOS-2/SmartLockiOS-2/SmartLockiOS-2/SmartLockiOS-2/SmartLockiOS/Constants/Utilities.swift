//
//  Utilities.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 29/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class Utilities: NSObject {

    // MARK: - Get current timestamp
    
    func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let date = Date()
        let strDate = dateFormatter.string(from: date)
        return strDate
    }
    
    func convertStringToDateFormat(withFormat format: String = "yyyy-MM-dd HH:mm:ss", dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        guard let date = dateFormatter.date(from: dateString) else {
            preconditionFailure("Take a look to your format")
        }
        return date
    }
    
    // MARK: - Validation Methods
    
    func isValidEmail(emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z].[A-Z0-9a-z_.]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$"
        
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailStr)
    }
    
    func isValidAddress(addressStr: String) -> Bool {
        let addressRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.+[&(),#])[A-Za-z\\d&(),#]{1,60}" // &/-_'()#,   // !@#$%&*().,
        let adressTest = NSPredicate(format:"SELF MATCHES %@", addressRegEx)
        return adressTest.evaluate(with: addressStr)
    }
    
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func setButtonProperties(button: UIButton) {
        button.backgroundColor = BUTTON_BGCOLOR
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
    }
    
    // MARK: - Empty check
    
    public static func isNilOrEmptyString(string: String?) -> Bool {
        switch string?.trimmingCharacters(in: .whitespaces) {
        case .some(let nonNilString):
            return nonNilString.isEmpty
        default:
            return true
        }
    }
    
    /*
     public static func isNilOrEmptyString(string: String?) -> Bool {
     switch string?.trimmingCharacters(in: .whitespaces) {
     case .some(let nonNilString):
     return nonNilString.isEmpty
     default:
     return true
     }
     }
     */
    
    // MARK: - Unicode character check
    
    func removeUnicodeCharacters(string: String) -> String {
        let possibleWhiteSpace: NSArray = [" ", "\t", "\n\r", "\n", "\r"] // here you add other types of white space
        //        var string:NSString = "some words \nanother word\n\r here something \tand something like \rmdjsbclsdcbsdilvb \n\rand finally this :)"
        //print(string) // initial string with white space
        var str = ""
        possibleWhiteSpace.enumerateObjects { (whiteSpace, _, _) -> Void in
            str = (string.replacingOccurrences(of: whiteSpace as! String, with: "") as NSString) as String
        }
        //print(str) // resulting string
        return str
    }
    
    // MARK: - Attributed text formatter
    
    func labelColorFormatter(firstStr: String, secondStr: String, thridStr: String) -> NSMutableAttributedString {
        var str1 = NSMutableAttributedString()
        var str2 = NSMutableAttributedString()
        var str3 = NSMutableAttributedString()
        
        str1 = NSMutableAttributedString(string: firstStr as String, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)])
        
        str2 = NSMutableAttributedString(string: secondStr as String, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14.0)])
        
        str3 = NSMutableAttributedString(string: thridStr as String, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)])
        
        str1.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: NSRange(location: 0, length: str1.length))
        str2.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: NSRange(location: 0, length: str2.length))
        str3.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: NSRange(location: 0, length: str3.length))
        
        // set label Attribute
        str1.append(NSMutableAttributedString(string: " "))
        str1.append(str2)
        str1.append(NSMutableAttributedString(string: " "))
        str1.append(str3)
        
        return str1
    }

    static func showErrorAlertView(message:String,presenter:UIViewController?){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in

            }
            var actualPresenter = presenter
            if actualPresenter == nil {
                actualPresenter = UIApplication.topViewController()
            }
            alertController.addAction(action)
            actualPresenter?.definesPresentationContext = true
            actualPresenter?.present(alertController, animated: true, completion: nil)
        }

    }

    static func showSuccessAlertView(message:String,presenter:UIViewController){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in

            }
            presenter.definesPresentationContext = true
            alertController.addAction(action)
            presenter.present(alertController, animated: true, completion: nil)
        }
    }
    
    static func showSuccessAlertViewWithHandler(message:String, presenter:UIViewController, completion:@escaping (Bool)->()){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                completion(true)
            }
            presenter.definesPresentationContext = true
            alertController.addAction(action)
            presenter.present(alertController, animated: true, completion: nil)
        }
    }
       
    func localToUTCForHardware(date:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.calendar = NSCalendar.current
        dateFormatter.timeZone = TimeZone.current

        let dt = dateFormatter.date(from: date)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "dd-MM-yy HH:mm:ss"

        return dateFormatter.string(from: dt!)
    }

    func localToUTC(date:String, _ isLockList:Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = isLockList ? "dd-MM-yyyy HH:mm" : "yyyy-MM-dd HH:mm:ss"
        dateFormatter.calendar = NSCalendar.current
        dateFormatter.timeZone = TimeZone.current

        let dt = dateFormatter.date(from: date)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = isLockList ? "dd-MM-yyyy HH:mm" : "yyyy-MM-dd HH:mm:ss"

        return dateFormatter.string(from: dt!)
    }
    

    // isScheduleAccess is True -> send 24 hrs format to api
    func UTCToLocal(date:String, _ isScheduleAccess:Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        guard let dt = dateFormatter.date(from: date) else { return "" }
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = (isDevice24Format() || isScheduleAccess) ? "dd-MM-yyyy HH:mm:ss" : "dd-MM-yyyy hh:mm:ss a"

        return dateFormatter.string(from: dt)
    }
    
    func isDevice24Format() -> Bool
    {
        let locale = NSLocale.current
        let formatter : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:locale)!
        return formatter.contains("a") ? false : true
    }
    
    func getTimeFromUTC(_ date: String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let dt = dateFormatter.date(from: date)
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = isDevice24Format() ? "HH:mm:ss" : "hh:mm:ss a"
        
        return dateFormatter.string(from: dt!)
    }

    func convertDateTimeFromUTC(_ date: String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dt = dateFormatter.date(from: date)
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = isDevice24Format() ? "dd-MM-yyyy HH:mm:ss" : "dd-MM-yyyy hh:mm:ss a"
        
        return dateFormatter.string(from: dt!)
    }

    func convertDateAndTimeFormatter(_ date: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = dateFormatter.date(from: date)
        dateFormatter.dateFormat = "dd-MM-yyyy hh:mm:ss a"
        return  dateFormatter.string(from: date!)
    }
    
    // MARK: - Date Conversion Methods
    
    func toDate(withFormat format: String = "yyyy-MM-dd", dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        guard let date = dateFormatter.date(from: dateString) else {
            preconditionFailure("Take a look to your format")
        }
        return date
    }
    
    func toDateString(withFormat format: String = "dd-MM-yyyy", date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func toTime(withFormat format: String = "HH:mm:ss", dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        guard let date = dateFormatter.date(from: dateString) else {
            preconditionFailure("Take a look to your format")
        }
        return date
    }
    
    func toTimeString(withFormat format: String = "hh:mm a", date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func to24HoursTimeString(withFormat format: String = "HH:mm", date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    // Get RFIDs - Default ids
    func getRFIDs() -> [Any] {
        var rfidArray = [Any]()
        for i in 0...2 {
            var dict = [String:String]()
            dict["key"] = String(i)
            dict["name"] = "RFID " + String(i+1)
            dict["slot_number"] = String(i)
            rfidArray.append(dict)
        }
        return rfidArray
    }
    
    // Convert Finger print "key" string value to key array value
    func convertKeyStringToKeyArray(with keyString: String) -> [String] {
        let keyStr1 = keyString.replacingOccurrences(of: "\"", with: "")
        let keyStr2 = keyStr1.replacingOccurrences(of: "[", with: "")
        let keyStr3 = keyStr2.replacingOccurrences(of: "]", with: "")
        var strArray = keyStr3.components(separatedBy:", ")
        if strArray.count == 1 {
            strArray = keyStr3.components(separatedBy:",")
        }
        return strArray// strArray.count
    }
    
    func convertKeyArrayToString(with keyArray: [String]) -> String {  // "[\"04\", \"06\"]"
        
        var keyString = "[\""
        for i in 0...keyArray.count-1 {
            if i == 0 {
                keyString = keyString + keyArray[i] + "\", "
            } else {
                keyString = keyString + "\"" + keyArray[i] + "\", "
            }
        }
        return keyString
    }
    
    // MARK: - Lock Keys Encryption
    
    /// Convert string to encrypted string
    /// - Parameter plainString: String to be encrypted
    func convertStringToEncryptedString(plainString: String,  isSecured: Bool) -> String {
        return isSecured ? encryptStingUsingAES(plainString: plainString, key: getencryptionKey(), iv: getencryptionIv()) ?? plainString : plainString
    }
    
    /// Encrypt string using AES
    /// - Parameters:
    ///   - plainString: String to be encrypted
    ///   - key: String
    ///   - iv: String
    ///   - options: kCCOptionPKCS7Padding
    func encryptStingUsingAES(plainString: String, key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
            let data = plainString.data(using: String.Encoding.utf8),
            let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {

            let keyLength              = size_t(kCCKeySizeAES128)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(options)

            var numBytesEncrypted :size_t = 0

            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyLength,
                                      iv,
                                      (data as NSData).bytes, data.count,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)

            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
                return base64cryptString
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    // MARK: - Lock Keys Decryption
    
    func decryptStringToPlainString(plainString: String, isSecured: Bool) -> String {
          
        return isSecured ? decryptStringUsingAES(plainString: plainString, key: getencryptionKey(), iv: getencryptionIv()) ?? plainString : plainString
    }

    func decryptStringUsingAES(plainString: String, key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
            let data = NSData(base64Encoded: plainString, options: .ignoreUnknownCharacters),
            let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {

            let keyLength              = size_t(kCCKeySizeAES128)
            let operation: CCOperation = UInt32(kCCDecrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(options)

            var numBytesEncrypted :size_t = 0

            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyLength,
                                      iv,
                                      data.bytes, data.length,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)

            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
                return unencryptedMessage
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    func getencryptionKey() -> String {
        let keychain = KeychainSwift()
        let password = "RNCryptorpassword"
        var key = ""
        let decryptValue = keychain.getData(KeychainKeys.encryptionKey.rawValue)
        do {
            let decryptData = try RNCryptor.decrypt(data: decryptValue!, withPassword: password)
            key = String(decoding: decryptData, as: UTF8.self)
            print("key ==> \(String(describing: key))")
        } catch {
            print(error)
        }
        return key
    }
    
    func getencryptionIv() -> String {
        let keychain = KeychainSwift()
        let password = "RNCryptorpassword"
        var iv = ""

        let decryptIvValue = keychain.getData(KeychainKeys.encryptionIV.rawValue)
        do {
            let decryptIvData = try RNCryptor.decrypt(data: decryptIvValue!, withPassword: password)
            iv = String(decoding: decryptIvData, as: UTF8.self)
            print("decryptedIvString ==> \(String(describing: iv))")
        } catch {
            print(error)
        }
        return iv
    }
    
}
extension UIApplication {

    class func topViewController(base: UIViewController? = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
