//
//  EditProfileViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 04/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SKCountryPicker
import libPhoneNumber_iOS

class EditProfileViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nameTextField: TweeAttributedTextField!
    @IBOutlet weak var emailTextField: TweeAttributedTextField!
    @IBOutlet weak var mobileTextField: TweeAttributedTextField!
    @IBOutlet weak var countryCodeButton: UIButton!

//    @IBOutlet weak var addressTextField: TweeAttributedTextField!
    
    @IBOutlet weak var addressPlaceholderLabel: UILabel!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var addressErrorLabel: UILabel!
    
    @IBOutlet weak var updateButton: UIButton!
    
    
    var profileObj = ProfileModel()
    
    var activeField: TweeAttributedTextField?
    var lastOffset: CGPoint!
    var keyboardHeight: CGFloat!
    lazy var country = Country(countryCode: "IN")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Initialize Methods
    
    func initialize() {
        self.title = "Edit Profile"
        self.addBackBarButton()
        self.setDelegates()
        self.setViewProperties()
        self.setButtonProperties()
        self.setTextViewProperties()
        
        self.updateTextFont()
        
        self.addressPlaceholderLabel.isHidden = false
        self.addressErrorLabel.isHidden = true
        self.addressTextView.textColor = UIColor.black
        self.addressTextView.backgroundColor = UIColor.white

        self.nameTextField.text = profileObj.name
        self.emailTextField.text = profileObj.email
        self.mobileTextField.text = profileObj.mobile
        self.addressTextView.text = profileObj.address
        country = Country(countryCode: profileObj.countryCode ?? "US")
        
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(returnTextView(gesture:))))
        self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
        self.countryCodeButton.setImage(country.flag, for: .normal)
        CountryManager.shared.resetLastSelectedCountry()
    }
    
    func updateTextFont() {
        self.nameTextField.font = UIFont.setRobotoRegular15FontForTitle
        self.emailTextField.font = UIFont.setRobotoRegular15FontForTitle
        self.mobileTextField.font = UIFont.setRobotoRegular15FontForTitle
        self.addressTextView.font = UIFont.setRobotoRegular15FontForTitle
        
        addressPlaceholderLabel.font = UIFont.setRobotoRegular10FontForTitle
        addressErrorLabel.font = UIFont.setRobotoRegular12FontForTitle

        self.updateButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
        self.countryCodeButton.titleLabel?.font = UIFont.setRobotoRegular14FontForTitle
        
    }
    
    func setDelegates() {
        self.nameTextField.delegate = self
        self.emailTextField.delegate = self
        self.mobileTextField.delegate = self
//        self.addressTextField.delegate = self
    }
    
    func setTextViewProperties() {
        addressTextView.text = "Address"
        addressTextView.textColor = UIColor.gray
        self.addressErrorLabel.isHidden = true
        self.addressPlaceholderLabel.isHidden = true
        addressTextView.delegate = self as! UITextViewDelegate
    }
    
    func setViewProperties() {
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.layer.masksToBounds = true
    }
    
    func setButtonProperties() {
        /*
        self.updateButton.isEnabled = false
        self.updateButton.isUserInteractionEnabled = false
        self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
 */
        self.updateButton.isUserInteractionEnabled = true
        self.updateButton.isEnabled = true
        self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
        self.updateButton.layer.cornerRadius = 5.0
        self.updateButton.layer.masksToBounds = true
//        self.updateButton.backgroundColor = UIColor.orange
    }
    
    @objc func returnTextView(gesture: UIGestureRecognizer) {
        guard activeField != nil else {
            return
        }
        
        activeField?.resignFirstResponder()
        activeField = nil
    }

    // MARK: - Navigation Bar Buttons
    
    func addBackBarButton() {
        
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToViewController), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapUpdateButton(_ sender: UIButton) {
        
        var errorMessage = ""
        
        if (self.nameTextField.text?.isEmpty)! {
            errorMessage = NAME_MANDATORY_ERROR
        } else if (self.nameTextField.text?.count)! > 25 {
            errorMessage = NAME_VALIDATION_ERROR
        }
        /*else if (self.emailTextField.text?.isEmpty)! {
            errorMessage = EMAIL_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: self.emailTextField.text!) {
            errorMessage = EMAIL_VALIDATION_ERROR
        } */
        else if (self.mobileTextField.text?.isEmpty)! {
            errorMessage = MOBILE_MANDATORY_ERROR
        } else if !(self.mobileNumberValidationCheck()) {
            errorMessage = MOBILE_VALIDATION_ERROR
        } else if (self.addressTextView.text?.isEmpty)! {
            errorMessage = ADDRESS_MANDATORY_ERROR
        } else if (self.addressTextView.text?.count)! > 60 {
            errorMessage = ADDRESS_VALIDATION_ERROR
        } else {
            // service call On success
            if profileObj.mobile != self.mobileTextField.text {
                let message = "Please confirm if you wanted to update the mobile number from '\(String(describing: profileObj.mobile!))' to '\(String(describing: self.mobileTextField.text!))'"
                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { action in
                }))
                alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
                    self.updateProfileDetails()
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.updateProfileDetails()
            }
        }
    }
    
    @objc func popToViewController() {
        self.navigationController! .popViewController(animated: false)
    }
    
    // MARK: - TextField Edit methods
    
    @IBAction func nameTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
//        self.validation()
        self.disableSignUpButton()
        nameTextField.hideInfo()
    }
    @IBAction func nameTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text != "" {
            self.validation()
            return
        }
        sender.showInfo(NAME_MANDATORY_ERROR)
    }
    
    
    @IBAction func emailTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
//        self.validation()
        self.disableSignUpButton()
        emailTextField.hideInfo()
    }
    @IBAction func emailTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if let emailText = sender.text, Utilities().isValidEmail(emailStr: emailText) == true {
            self.validation()
            return
        }
        if sender.text == "" {
            sender.showInfo(EMAIL_MANDATORY_ERROR)
        } else {
            sender.showInfo(EMAIL_VALIDATION_ERROR)
        }
    }
    
    @IBAction func mobileTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
//        self.validation()
        self.disableSignUpButton()
        mobileTextField.hideInfo()
    }
    @IBAction func mobileTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        
        
        if mobileNumberValidationCheck() {
            if sender.text == "0000000000" {
               sender.showInfo(MOBILE_VALIDATION_ERROR)
                self.disableSignUpButton()
            } else {
                self.validation()
                return
            }
        }else {
            sender.showInfo(MOBILE_VALIDATION_ERROR)
            self.disableSignUpButton()
        }
        
//        if sender.text?.count == 10 {
//            /*
//             if isValidMobile(value: sender.text!) {
//             return
//             }*/
//            if sender.text == "0000000000" {
//                sender.showInfo(MOBILE_VALIDATION_ERROR)
//            } else {
//                self.validation()
//                return
//            }
//
//        }
//        if sender.text == "" {
//            sender.showInfo(MOBILE_MANDATORY_ERROR)
//        } else {
//            sender.showInfo(MOBILE_VALIDATION_ERROR)
//        }
    }
    
    /*
    @IBAction func addressTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        addressTextField.hideInfo()
    }
    
    @IBAction func addressTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text != "" {
            return
        }
        if sender.text == "" {
            sender.showInfo(ADDRESS_MANDATORY_ERROR)
        } else {
            sender.showInfo(ADDRESS_VALIDATION_ERROR)
        }
    }
    */
    // MARK: - Service call
    
    func updateProfileDetails() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "users/updateprofile"
        
        /*
         "username":"spn",
         "password":"Payoda@123",
         "email":"spn@payoda.com",
         "mobile":"7788778877",
         "address":"kdfjvhiek",
         */
        
        /*
        let userDetailsDict = [ "username": "\(self.nameTextField.text ?? "")" ,
            "email": "\(self.emailTextField.text ?? "")" ,
            "mobile": "\(self.mobileTextField.text ?? "")",
            "address": "\(self.addressTextField.text ?? "")"
        ]*/
        
//        let userDetailsDict = [ "username": "Geetha" ,
//            "email": "geethanjali.n@payoda.com" ,
//            "mobile": "9876543211",
//            "address": "CBE"
//        ]
        
       // /*
         let userDetailsDict = [ "name": "\(self.nameTextField.text ?? "")" ,
         "email": "\(self.emailTextField.text ?? "")" ,
         "mobile": "\(self.mobileTextField.text ?? "")",
         "address": "\(self.addressTextView.text ?? "")",
         "country_code": "\(self.country.countryCode )"
         ]
// */
        
        var userDetails = [ String : String ]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            // here "decoded" is of type `Any`, decoded from JSON data
            
            // you can now cast it with the right type
            if let dictFromJSON = decoded as? [String:String] {
                // use dictFromJSON
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        ProfileViewModel().updateProfileViewModel(url: urlString, userDetails: userDetails as [String : String], callback: { (result, error) in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                let userNameString = self.nameTextField.text!
                let keychain = KeychainSwift()
                let password = "RNCryptorpassword"
                let enteredPinData = userNameString.data(using: .utf8)
                let encryptedData = RNCryptor.encrypt(data: enteredPinData!, withPassword: password)
                keychain.set(encryptedData, forKey: KeychainKeys.userName.rawValue)
                
                let message = result!["message"].rawValue as! String
                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - Validation
    
    func validation() {
        self.updateButton.isEnabled = false
        self.updateButton.isUserInteractionEnabled = false
        self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
        var errorMessage = ""
        
        if (self.nameTextField.text?.isEmpty)! {
            errorMessage = NAME_MANDATORY_ERROR
        } else if (self.nameTextField.text?.count)! > 25 {
            errorMessage = NAME_VALIDATION_ERROR
        }
        /*
        else if (self.emailTextField.text?.isEmpty)! {
            errorMessage = EMAIL_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: self.emailTextField.text!) {
            errorMessage = EMAIL_VALIDATION_ERROR
        } */
        else if (self.mobileTextField.text?.isEmpty)! {
            errorMessage = MOBILE_MANDATORY_ERROR
        } else if !(self.mobileNumberValidationCheck()) {
            errorMessage = MOBILE_VALIDATION_ERROR
        } else if (self.addressTextView.text?.isEmpty)! || self.addressTextView.text == "Address" {
            errorMessage = ADDRESS_MANDATORY_ERROR
        } else if (self.addressTextView.text?.count)! > 60 {
            errorMessage = ADDRESS_VALIDATION_ERROR
        } else {
            // On success
            //            self.successView.isHidden = false
            //            self.contentView.isHidden = true
            
            self.updateButton.isUserInteractionEnabled = true
            self.updateButton.isEnabled = true
            self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
            //            service call
        }
    }
    
    // MARK: - Validation Methods
    
    func isValidMobile(value: String) -> Bool {
        let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result =  phoneTest.evaluate(with: value)
        return result
    }
    
}



// MARK: - UITextFieldDelegate
extension EditProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField as? TweeAttributedTextField
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    /*
     func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     if string.rangeOfCharacter(from: NSCharacterSet.letters) != nil {
     return true
     } else {
     return false
     }
     }
     */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        activeField?.resignFirstResponder()
        activeField = nil
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //print("in string \(String(describing: textField.text)) \(string)")
        if textField == self.nameTextField {
            let alphabetSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ ")

            if (string.rangeOfCharacter(from: alphabetSet) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) && (textField.text?.count)! < 25 {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                if textField.text != nil {
                    if textField.text!.last == " " && string == " "{
                        return false
                    }
                }
                return true
            } else if(string == "") {
                
                //print("Backspace pressed");
                return true;
                
            } else {
                return false
            }
        } else if textField == self.mobileTextField {
            if (textField.text?.count)! < 15 {
                return true
            } else if(string == "") {
                
                //print("Backspace pressed");
                return true;
                
            }  else {
                return false
            }
            
        }
        /*else if textField == self.addressTextField {
            if (textField.text?.count)! < 60 {
                return true
            } else {
                return false
            }
        }*/
        return true
    }
}

extension EditProfileViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.disableSignUpButton()
        self.addressErrorLabel.isHidden = true
        if textView.textColor == UIColor.gray {
            self.addressPlaceholderLabel.isHidden = false
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView == self.addressTextView {
            if (text.rangeOfCharacter(from: NSCharacterSet.letters) != nil || text.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil || text.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil || text == "&" || text == "/" || text == "-" || text == "_" || text == "'" || text == "(" || text == ")" || text == "#" || text == ",") && (textView.text?.count)! < 60 {
                if range.location == 0 && text.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                return true
            } else if(text == "") {
                
                //print("Backspace pressed");
                return true;
                
            } else {
                return false
            }
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text.isEmpty {
            textView.text = "Address"
            textView.textColor = UIColor.gray
            
            self.addressPlaceholderLabel.isHidden = true
            self.addressErrorLabel.isHidden = false
            self.addressErrorLabel.text = ADDRESS_MANDATORY_ERROR
        }
        self.validation()
        
    }
    func disableSignUpButton(){
        self.updateButton.isEnabled = false
        self.updateButton.isUserInteractionEnabled = false
        self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
    }
    
}

/// Country code selection and validation
extension EditProfileViewController {
    
    @IBAction func btnCountryCodeAction(_ sender: Any) {
      //  presentCountryPickerScene(withSelectionControlEnabled: true)
    }
    /// Dynamically presents country picker scene with an option of including `Selection Control`.
    ///
    /// By default, invoking this function without defining `selectionControlEnabled` parameter. Its set to `True`
    /// unless otherwise and the `Selection Control` will be included into the list view.
    ///
    /// - Parameter selectionControlEnabled: Section Control State. By default its set to `True` unless otherwise.
//    
//    func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
//        switch selectionControlEnabled {
//        case true:
//            // Present country picker with `Section Control` enabled
//            let countryController = CountryPickerWithSectionViewController.presentController(on: self) { [weak self] (country: Country) in
//                
//                guard let self = self else { return }
//                self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
//                self.countryCodeButton.setImage(country.flag, for: .normal)
//                self.country = country
//                //self.validation()
//                if !(self.mobileNumberValidationCheck()) {
//                    self.updateButton.isEnabled = false
//                    self.updateButton.isUserInteractionEnabled = false
//                    self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
//                    
//                    self.mobileTextField.showInfo(MOBILE_VALIDATION_ERROR)
//                }else {
//                    self.mobileTextField.hideInfo()
//                    
//                    self.updateButton.isUserInteractionEnabled = true
//                    self.updateButton.isEnabled = true
//                    self.updateButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
//                }
//            }
//            
//            countryController.flagStyle = .circular
//            countryController.isCountryFlagHidden = false
//            countryController.isCountryDialHidden = false
//            //countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
//            
//
//        case false:
//            // Present country picker without `Section Control` enabled
//            let countryController = CountryPickerController.presentController(on: self) { [weak self] (country: Country) in
//                
//                guard let self = self else { return }
//                
//                self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
//                self.countryCodeButton.setImage(country.flag, for: .normal)
//                self.country = country
//            }
//            
//            countryController.flagStyle = .corner
//            countryController.isCountryFlagHidden = false
//            countryController.isCountryDialHidden = false
//            //countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
//        }
//    }
//    
    func mobileNumberValidationCheck() -> Bool{
        guard let phoneUtil = NBPhoneNumberUtil.sharedInstance() else {
               return false
           }
        var isValidPhoneNumber = Bool()
           do {
            let phoneNumber: NBPhoneNumber = try phoneUtil.parse(self.mobileTextField.text, defaultRegion: self.country.countryCode)
             isValidPhoneNumber =  phoneUtil.isValidNumber(forRegion: phoneNumber, regionCode: self.country.countryCode)
           }
           catch let error as NSError {
               print(error.localizedDescription)
           }
        return isValidPhoneNumber
    }
    
}
