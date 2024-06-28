//
//  SignUpViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 25/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SafariServices
import SKCountryPicker
import libPhoneNumber_iOS


class SignUpViewController: UIViewController {

    @IBOutlet weak var successView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var addressPlaceholderLabel: UILabel!
    @IBOutlet weak var nameTextField: TweeAttributedTextField!
    @IBOutlet weak var emailTextField: TweeAttributedTextField!
    @IBOutlet weak var passwordTextField: TweeAttributedTextField!
    @IBOutlet weak var confirmPasswordTextField: TweeAttributedTextField!
    @IBOutlet weak var mobileTextField: TweeAttributedTextField!
//    @IBOutlet weak var addressTextField: TweeAttributedTextField!
    
    @IBOutlet weak var termsAndConditionsButton: UIButton?
    @IBOutlet weak var privacyPolicyButton: UIButton?
    @IBOutlet weak var countryCodeButton: UIButton!



    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var addressErrorLabel: UILabel!
    
    @IBOutlet weak var signUpButton: UIButton!

    @IBOutlet weak var signInButton: UIButton!
    
    
    @IBOutlet weak var successTextlabel: UILabel!
    
    @IBOutlet weak var passwordInstructionLabel: UILabel!
    
    
    
    var customBackBtnItem = UIBarButtonItem()
    var isFromForgotPassword = Bool()
    var isSignUpEnabled = false
    var activeField: TweeAttributedTextField?
    var lastOffset: CGPoint!
    lazy var strTermsAndConditions = Bundle.main.object(forInfoDictionaryKey: "TermsAndConditions") as! String
    lazy var strPrivacyPolicy = Bundle.main.object(forInfoDictionaryKey: "PrivacyUrl") as! String
    lazy var country = Country(countryCode: "IN")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addressTextView.textColor = UIColor.black
        self.addressTextView.backgroundColor = UIColor.white

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
        self.title = "Sign Up"
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.addBackBarButton()
        self.updateTextFont()
        self.setDelegates()
        self.setViewProperties()
        self.setButtonProperties()
        self.setTextViewProperties()
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(returnTextView(gesture:))))
        self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
        self.countryCodeButton.setImage(country.flag, for: .normal)
        CountryManager.shared.resetLastSelectedCountry()
    }
    
    func updateTextFont() {
        
        instructionLabel.font = UIFont.setRobotoRegular15FontForTitle
        addressPlaceholderLabel.font = UIFont.setRobotoRegular10FontForTitle
        nameTextField.font = UIFont.setRobotoRegular14FontForTitle
        emailTextField.font = UIFont.setRobotoRegular14FontForTitle
        passwordTextField.font = UIFont.setRobotoRegular14FontForTitle
        confirmPasswordTextField.font = UIFont.setRobotoRegular14FontForTitle
        addressTextView.font = UIFont.setRobotoRegular18FontForTitle
        mobileTextField.font = UIFont.setRobotoRegular14FontForTitle
        addressErrorLabel.font = UIFont.setRobotoRegular12FontForTitle
        successTextlabel.font = UIFont.setRobotoRegular25FontForTitle
        passwordInstructionLabel.font = UIFont.setRobotoRegular14FontForTitle
        
        signInButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
        signUpButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
        countryCodeButton.titleLabel?.font = UIFont.setRobotoRegular14FontForTitle
    }
    
    func setDelegates() {
        self.nameTextField.delegate = self
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.confirmPasswordTextField.delegate = self
        self.mobileTextField.delegate = self
//        self.addressTextField.delegate = self
    }
    
    func setTextViewProperties() {
        addressTextView.text = "Address"
        addressTextView.textColor = UIColor.darkGray
        self.addressErrorLabel.isHidden = true
        self.addressPlaceholderLabel.isHidden = true
        addressTextView.delegate = self as UITextViewDelegate
    }
    
    func setViewProperties() {
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.layer.masksToBounds = true
    }
    
    func setButtonProperties() {
        self.signUpButton.isEnabled = false
        self.signUpButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
        self.signUpButton.isUserInteractionEnabled = false
        self.signUpButton.layer.cornerRadius = 5.0
        self.signUpButton.layer.masksToBounds = true
        
        self.signInButton.isUserInteractionEnabled = true
        self.signInButton.layer.cornerRadius = 5.0
        self.signInButton.layer.masksToBounds = true
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
        customBackBtnItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    // MARK: - Validation
    
    func validation() {
        self.signUpButton.isEnabled = false
        self.signUpButton.isUserInteractionEnabled = false
        self.signUpButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
        var errorMessage = ""
        
        if (self.nameTextField.text?.isEmpty)! {
            errorMessage = NAME_MANDATORY_ERROR
        } else if (self.nameTextField.text?.count)! > 25 {
            errorMessage = NAME_VALIDATION_ERROR
        } else if (self.emailTextField.text?.isEmpty)! {
            errorMessage = EMAIL_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: self.emailTextField.text!) {
            errorMessage = EMAIL_VALIDATION_ERROR
        } else if (self.passwordTextField.text?.isEmpty)! {
            errorMessage = PASSWORD_MANDATORY_ERROR
        } else if !isValidPassword(passwordStr: self.passwordTextField.text!) {
            errorMessage = PASSWORD_VALIDATION_ERROR
        } else if (self.confirmPasswordTextField.text?.isEmpty)! {
            errorMessage = CONFIRM_PASSWORD_MANDATORY_ERROR
        } else if (self.confirmPasswordTextField.text)! != (self.passwordTextField.text)! {
            errorMessage = PASSWORD_MATCH_ERROR
        } else if (self.mobileTextField.text?.isEmpty)! {
            errorMessage = MOBILE_MANDATORY_ERROR
        }else if !(self.mobileNumberValidationCheck()) {
            errorMessage = MOBILE_VALIDATION_ERROR
        }  else if (self.addressTextView.text?.isEmpty)! || self.addressTextView.text == "Address" {
            errorMessage = ADDRESS_MANDATORY_ERROR
        } else if (self.addressTextView.text?.count)! > 60 {
            errorMessage = ADDRESS_VALIDATION_ERROR
            self.addressErrorLabel.isHidden = false
            self.addressErrorLabel.text = ADDRESS_VALIDATION_ERROR
        } else {
            // On success
//            self.successView.isHidden = false
//            self.contentView.isHidden = true
            
            self.signUpButton.isUserInteractionEnabled = true
            self.signUpButton.isEnabled = true
            self.signUpButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapTermsAndConditionsButton(_ sender: UIButton) {
        /*
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let lockDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "TermsAndPolicyViewController") as! TermsAndPolicyViewController
        lockDetailsViewController.titleString = "Terms and Conditions"
        self.navigationController?.pushViewController(lockDetailsViewController, animated: true)
        */
        
        let termsConditionURL:String? = JsonUtils().getValueByKey(key: "terms_condition_url") as? String
        var safariVC:SFSafariViewController?
        if(termsConditionURL != nil){
            safariVC = SFSafariViewController(url: URL(string:termsConditionURL!)!)
        }else {
            safariVC = SFSafariViewController(url: URL(string:strTermsAndConditions)!)
        }
        self.navigationController?.present(safariVC!, animated: true, completion: nil)
        
    }
    
    
    @IBAction func onTapPrivacyPolicyButton(_ sender: UIButton) {
        /*
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let lockDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "TermsAndPolicyViewController") as! TermsAndPolicyViewController
        
        lockDetailsViewController.titleString = "Privacy Policy"
 self.navigationController?.pushViewController(lockDetailsViewController, animated: true)
        */
        
        let privacyPolicyURL:String? = JsonUtils().getValueByKey(key: "privacy_url") as? String
        var safariVC:SFSafariViewController?
        if(privacyPolicyURL != nil){
            safariVC = SFSafariViewController(url: URL(string:privacyPolicyURL!)!)
        }else {
            safariVC = SFSafariViewController(url: URL(string:strPrivacyPolicy)!)
        }
        self.navigationController?.present(safariVC!, animated: true, completion: nil)

    }
    
    
    @IBAction func onTapSignInButton(_ sender: UIButton) {
//        self.navigationController?.popViewController(animated: true)
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func onTapSignUpButton(_ sender: UIButton) {
        
        var errorMessage = ""
        
        if (self.nameTextField.text?.isEmpty)! {
            errorMessage = NAME_MANDATORY_ERROR
        } else if (self.nameTextField.text?.count)! > 25 {
            errorMessage = NAME_VALIDATION_ERROR
        } else if (self.emailTextField.text?.isEmpty)! {
            errorMessage = EMAIL_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: self.emailTextField.text!) {
            errorMessage = EMAIL_VALIDATION_ERROR
        } else if (self.passwordTextField.text?.isEmpty)! {
            errorMessage = PASSWORD_MANDATORY_ERROR
        } else if !isValidPassword(passwordStr: self.passwordTextField.text!) {
            errorMessage = PASSWORD_VALIDATION_ERROR
        } else if (self.confirmPasswordTextField.text?.isEmpty)! {
            errorMessage = CONFIRM_PASSWORD_MANDATORY_ERROR
        } else if (self.confirmPasswordTextField.text)! != (self.passwordTextField.text)! {
            errorMessage = PASSWORD_MATCH_ERROR
        } else if (self.mobileTextField.text?.isEmpty)! {
            errorMessage = MOBILE_MANDATORY_ERROR
        } else if !(self.mobileNumberValidationCheck()) {
            errorMessage = MOBILE_VALIDATION_ERROR
        } else if (self.addressTextView.text?.isEmpty)! {
            errorMessage = ADDRESS_MANDATORY_ERROR
        } else if (self.addressTextView.text?.count)! > 60 {
            errorMessage = ADDRESS_VALIDATION_ERROR
        } else {
            // service call On success
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
             LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            
            let urlString = ServiceUrl.BASE_URL + "users/createuser"
            
            /*
            "username":"spn",
            "password":"Payoda@123",
            "email":"spn@payoda.com",
            "mobile":"7788778877",
            "address":"kdfjvhiek",
            */
            
            
            let userDetailsDict = [ "name": "\(self.nameTextField.text ?? "")" ,
                                "password": "\(self.passwordTextField.text ?? "")" ,
                "email": "\(self.emailTextField.text ?? "")" ,
                "mobile": "\(self.mobileTextField.text ?? "")",
                "address": "\(self.addressTextView.text ?? "")",
                "country_code": "\(self.country.countryCode )"
            ]

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
            
            SignUpViewModel().signUpServiceViewModel(url: urlString, userDetails: userDetails as [String : String], callback: { (result, error) in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.navigationController?.navigationBar.isUserInteractionEnabled = true
                
                //print("Result ==> \(result)")
                if result != nil {
                    
                    self.instructionLabel.text = "An email with an activation link has been sent to the registered email address, " + self.emailTextField.text! + ". Please activate the account to proceed."
                    self.successView.isHidden = false
                    self.view.bringSubviewToFront(self.successView)
                    self.contentView.isHidden = true
                    self.scrollView.isHidden = true
                    self.navigationItem.leftBarButtonItem = nil
//                    self.navigationItem.setHidesBackButton(true, animated:true)
                } else {
                    let message = error?.userInfo["ErrorMessage"] as! String
                    self.view.makeToast(message)
//                    let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                    }))
//                    self.present(alert, animated: true, completion: nil)
                }
            })
            
            
            /*
 
             SignUpViewModel().signUpServiceViewModel(url: urlString, userDetails: userDetails as [String : String], callback: { (result) in
             
             LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
             
             //print("Result ==> \(result)")
             if result["status"] as! String == "success" {
             self.instructionLabel.text = "An email with an activation link has been sent to the registered email address, " + self.emailTextField.text! + ". Please activate the account to proceed."
             self.successView.isHidden = false
             self.view.bringSubview(toFront: self.successView)
             self.contentView.isHidden = true
             self.scrollView.isHidden = true
             self.navigationItem.leftBarButtonItem = nil
             //                    self.navigationItem.setHidesBackButton(true, animated:true)
             } else {
             let message = result["message"] as! String
             let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
             
             alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
             }))
             self.present(alert, animated: true, completion: nil)
             }
             })
 */
        }
        
        
        
        
        
    }
    
    @objc func popToViewController() {
        /*if isFromForgotPassword {
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.navigationController! .popViewController(animated: false)
        }*/
        self.navigationController! .popViewController(animated: false)
    }
    
    // MARK: - TextField Edit methods

    @IBAction func nameTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
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
        self.validation()
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
    
    
    @IBAction func passwordTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        passwordTextField.hideInfo()
    }
    
    @IBAction func passwordTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if isValidPassword(passwordStr: sender.text!) {
            self.validation()
            return
        }
        if sender.text == "" {
            sender.showInfo(PASSWORD_MANDATORY_ERROR)
        } else if (sender.text?.count)! > 8 {
            sender.showInfo(PASSWORD_VALIDATION_ERROR)
        } else {
            sender.showInfo(PASSWORD_VALIDATION_ERROR)
        }
        
    }
    
    
    @IBAction func confirmPasswordTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        confirmPasswordTextField.hideInfo()
        
    }
    
    @IBAction func confirmPasswordTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        
        
        if sender.text == "" {
            sender.showInfo(CONFIRM_PASSWORD_MANDATORY_ERROR)
        } else if self.passwordTextField.text == sender.text {
            self.validation()
            return
        } else if (sender.text?.count)! > 8 {
            sender.showInfo(PASSWORD_MATCH_ERROR)
        } else {
            sender.showInfo(PASSWORD_MATCH_ERROR)
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
//            if isValidMobile(value: sender.text!) {
//                return
//            }*/
//            if sender.text == "0000000000" {
//               sender.showInfo(MOBILE_VALIDATION_ERROR)
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
    
    
//    @IBAction func addressTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
//        self.validation()
//        addressTextField.hideInfo()
//    }
//
//    @IBAction func addressTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
//        self.validation()
//        if sender.text != "" {
//            return
//        }
//        sender.showInfo("Address consists of max 60 chars")
//    }
    
    
    // MARK: - Validation Methods

    func isValidPassword(passwordStr: String) -> Bool {
//        let passwordRegEx = "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z])(?=.*[!@#$%&*()-.,]).{8,16}$"
        
       let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%&*().,])[A-Za-z\\d!@#$%&*().,]{8,16}"
        
//        ^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}
        
//        let passwordRegEx = "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z])(?=.*[!@#$%&*()-_.,]).{8,16}$"

        let passwordTest = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordTest.evaluate(with: passwordStr)
    }
    
    func isValidMobile(value: String) -> Bool {
        let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result =  phoneTest.evaluate(with: value)
        return result
    }
    
}



// MARK: - UITextFieldDelegate
extension SignUpViewController: UITextFieldDelegate {
  
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
        if textField == self.nameTextField {
            /*
            if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage])
            {
                return NO;
            }
 */
            
//            if textField.textInputMode?.primaryLanguage != "emoji"  {
//                return false
//            }
            
            if (string.rangeOfCharacter(from: NSCharacterSet.letters) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) && (textField.text?.count)! < 25    {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                return true
            } else if(string == "") {
                
                //print("Backspace pressed");
                return true;
            
            } else {
                return false
            }
        } else if textField == self.passwordTextField || textField == self.confirmPasswordTextField {
            if(textField.text?.count)! < 16 {
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
    
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if textField == self.passwordTextField || textField == self.confirmPasswordTextField {
//
//            if (textField.text?.count)! > 8 {
//                textField.showInfo(PASSWORD_VALIDATION_ERROR)
//            }
//        }
//
//    }
}

extension SignUpViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.addressErrorLabel.isHidden = true
        if textView.textColor == UIColor.darkGray {
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
            textView.textColor = UIColor.darkGray
            
            self.addressPlaceholderLabel.isHidden = true
            self.addressErrorLabel.isHidden = false
            self.addressErrorLabel.text = ADDRESS_MANDATORY_ERROR

        } else {
            self.validation()
        }
    }
    
    func disableSignUpButton(){
        self.signUpButton.isEnabled = false
        self.signUpButton.isUserInteractionEnabled = false
        self.signUpButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
    }
    
}

/// Country code selection and validation
extension SignUpViewController {
    
    @IBAction func btnCountryCodeAction(_ sender: Any) {
       // presentCountryPickerScene(withSelectionControlEnabled: true)
    }
    /// Dynamically presents country picker scene with an option of including `Selection Control`.
    ///
    /// By default, invoking this function without defining `selectionControlEnabled` parameter. Its set to `True`
    /// unless otherwise and the `Selection Control` will be included into the list view.
    ///
    /// - Parameter selectionControlEnabled: Section Control State. By default its set to `True` unless otherwise.
    
    // func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
    //     switch selectionControlEnabled {
    //     case true:
    //         // Present country picker with `Section Control` enabled
    //         let countryController = CountryPickerWithSectionViewController.presentController(on: self) { [weak self] (country: Country) in
                
    //             guard let self = self else { return }
                
    //             self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
    //             self.countryCodeButton.setImage(country.flag, for: .normal)
    //             self.country = country
    //         }
            
    //         countryController.flagStyle = .circular
    //         countryController.isCountryFlagHidden = false
    //         countryController.isCountryDialHidden = false
    //         //countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]

    //     case false:
    //         // Present country picker without `Section Control` enabled
    //         let countryController = CountryPickerController.presentController(on: self) { [weak self] (country: Country) in
                
    //             guard let self = self else { return }
                
    //             self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
    //             self.countryCodeButton.setImage(country.flag, for: .normal)
    //             self.country = country
    //         }
            
    //         countryController.flagStyle = .corner
    //         countryController.isCountryFlagHidden = false
    //         countryController.isCountryDialHidden = false
    //         //countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
    //     }
    // }

//    func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
//    switch selectionControlEnabled {
//    case true:
//        // Present country picker with `Section Control` enabled
//        let countryController = CountryPickerWithSectionViewController.presentController(on: self) { [weak self] (country: Country) in
//            guard let self = self else { return }
//            
//            self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
//            self.countryCodeButton.setImage(country.flag, for: .normal)
//            self.country = country
//        }
//        
//        // Check if these properties are available on CountryPickerWithSectionViewController
//        if let picker = countryController as? CountryPickerWithSectionViewController {
//            picker.flagStyle = .circular
//            picker.isCountryFlagHidden = false
//            picker.isCountryDialHidden = false
//            // picker.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
//        }
//
//    case false:
//        // Present country picker without `Section Control` enabled
//        let countryController = CountryPickerController.presentController(on: self) { [weak self] (country: Country) in
//            guard let self = self else { return }
//            
//            self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
//            self.countryCodeButton.setImage(country.flag, for: .normal)
//            self.country = country
//        }
//        
//        // Check if these properties are available on CountryPickerController
//        if let picker = countryController as? CountryPickerController {
//            picker.flagStyle = .corner
//            picker.isCountryFlagHidden = false
//            picker.isCountryDialHidden = false
//            // picker.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
//        }
//    }
//}

    
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
