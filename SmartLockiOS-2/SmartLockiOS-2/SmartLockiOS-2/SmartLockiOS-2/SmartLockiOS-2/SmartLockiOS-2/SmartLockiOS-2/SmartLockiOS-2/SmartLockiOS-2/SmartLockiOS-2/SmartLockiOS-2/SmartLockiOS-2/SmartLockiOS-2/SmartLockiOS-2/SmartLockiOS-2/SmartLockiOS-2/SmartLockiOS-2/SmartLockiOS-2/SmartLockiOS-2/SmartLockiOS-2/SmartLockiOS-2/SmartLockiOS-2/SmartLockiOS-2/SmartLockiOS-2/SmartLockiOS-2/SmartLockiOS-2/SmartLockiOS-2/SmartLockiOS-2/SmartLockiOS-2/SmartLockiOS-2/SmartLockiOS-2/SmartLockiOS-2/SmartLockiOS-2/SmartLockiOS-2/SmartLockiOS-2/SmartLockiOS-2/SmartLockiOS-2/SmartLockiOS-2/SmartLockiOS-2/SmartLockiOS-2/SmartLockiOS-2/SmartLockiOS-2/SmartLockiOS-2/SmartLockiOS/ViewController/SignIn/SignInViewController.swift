//
//  SignInViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 25/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var errorMessageView: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    @IBOutlet weak var errorButton: UIButton!
    
    @IBOutlet weak var emailTextField: TweeAttributedTextField!
    @IBOutlet weak var passwordTextField: TweeAttributedTextField!
    @IBOutlet weak var passwordShowHideButton: UIButton!
   
    /*
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordLineLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailCloseButton: UIButton!
    @IBOutlet weak var emailLineLabel: UILabel!
    */
    
    
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var forgotPassword: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    var activeField: UITextField?
    var lastOffset: CGPoint!
    
    var isSignInTapped = false
    var isPasswordHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false//true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        UINavigationBar.appearance().isTranslucent = true//false
        self.updateTextFont()
        self.setDelegates()
//        self.setTextFieldProperties()
        self.setButtonProperties()
        self.initializeView()
        
        if isSignInTapped {
            
        } else {
            if isPasswordHidden {
                // eye strike img
                passwordShowHideButton.setImage(UIImage(named: "hidePassword"), for: .normal)
            } else {
                // eye image
                passwordShowHideButton.setImage(UIImage(named: "showPassword"), for: .normal)
            }
        }
    }
    
    func updateTextFont() {
        logoImageView.image = UIImage.init(named: AppLogo)
        emailTextField.font = UIFont.setRobotoRegular14FontForTitle
        passwordTextField.font = UIFont.setRobotoRegular14FontForTitle
        
        signInButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
        forgotPassword.titleLabel?.font = UIFont.setRobotoMedium18FontForTitle
        signUpButton.titleLabel?.font = UIFont.setRobotoMedium18FontForTitle
    }
    
    func setDelegates() {
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    func setTextFieldProperties() {
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    func initializeView() {
        self.emailTextField.text = ""
        self.passwordTextField.text = ""
//        self.errorMessageView.isHidden = true
//        emailCloseButton.isHidden = true
        isSignInTapped = false        
    }
    
    func setButtonProperties() {
        self.signInButton.isEnabled = false
        self.signInButton.isUserInteractionEnabled = false
        self.signInButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.7)
        self.signInButton.layer.cornerRadius = 5.0
        self.signInButton.layer.masksToBounds = true
    }
    
    // MARK: - Navigation methods
    
    func navigateToCreatePinVC() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let pinViewController = storyBoard.instantiateViewController(withIdentifier: "PinViewController") as! PinViewController
        pinViewController.isFromLogin = true
        pinViewController.isFromResetPIN = false
        self.navigationController?.pushViewController(pinViewController, animated: true)
    }
    
    // MARK: - Button Actions
    /*
    @IBAction func onTapEmailCloseButton(_ sender: UIButton) {
        // remove text
        self.emailTextField.text = ""
        self.emailCloseButton.isHidden = true
    }*/
    @IBAction func onTapErrorButton(_ sender: UIButton) {
//        self.errorMessageView.isHidden = true
    }
    
    @IBAction func onTapPasswordShowHideButton(_ sender: UIButton) {
        var icon = ""
        isPasswordHidden = !isPasswordHidden
        if isPasswordHidden {
            // change to hide password ==> eye strike
            icon = "hidePassword"
            passwordTextField.isSecureTextEntry = true
            
        } else {
            // change to show password ==> eye
            icon = "showPassword"
            passwordTextField.isSecureTextEntry = false
        }
        
        if isSignInTapped {
            passwordTextField.text = ""
            isSignInTapped = !isSignInTapped
        } else {
            
        }
        
        passwordShowHideButton.setImage(UIImage(named: icon), for: .normal)
    }
    
    func fieldValidation() {
        self.signInButton.isEnabled = false
        self.signInButton.isUserInteractionEnabled = false
        self.signInButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.7)
        if emailTextField.text == "" {
            self.errorMessageLabel.text = EMAIL_MANDATORY_ERROR
        } else if passwordTextField.text == "" {
            self.errorMessageLabel.text = PASSWORD_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: emailTextField.text!) {
            self.errorMessageLabel.text = EMAIL_VALIDATION_ERROR
        } else {
            self.signInButton.isEnabled = true
            self.signInButton.isUserInteractionEnabled = true
            self.signInButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
        }
    }
    
    @IBAction func onTapSignInButton(_ sender: UIButton) {
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
//        self.errorMessageView.isHidden = false
        if emailTextField.text == "" {
            self.errorMessageLabel.text = EMAIL_MANDATORY_ERROR
        } else if passwordTextField.text == "" {
            self.errorMessageLabel.text = PASSWORD_MANDATORY_ERROR
        } else if !Utilities().isValidEmail(emailStr: emailTextField.text!) {
            self.errorMessageLabel.text = EMAIL_VALIDATION_ERROR
        } else {
           
//            self.errorMessageView.isHidden = true
//            self.errorMessageLabel.text = ""
            
            
            // Service call
            /*
            let urlString = "http://localhost/smart_app/api/web/v1/users/login"
            
            var userDetails = [String : AnyObject]()
            userDetails["username"] = self.emailTextField.text!  as AnyObject
            userDetails["password"] = self.passwordTextField.text! as AnyObject
            */
            
            let urlString = ServiceUrl.BASE_URL + "users/login"
            //print("login URL ==> \(urlString)")
            /*
             "username":"spn",
             "password":"Payoda@123",
             "email":"spn@payoda.com",
             "mobile":"7788778877",
             "address":"kdfjvhiek",
             */
            
            /*
             
             {
             "password":"Payoda@123",
             "email":"sps@payoda.com",
             "deviceToken":"7788778877"  /* For Push notification*/
             "deviceId":"7788778877"       /* For Unique Identification */
             }

 
 */
            
            var deviceId = NSUUID().uuidString
            //print("deviceId ==> \(deviceId)")
            deviceId = deviceId.replacingOccurrences(of: "-", with: "")
            let deviceToken = UserDefaults.standard.object(forKey: "Push_Token") ?? "1"
           print("deviceToken = \(deviceToken)")
            let userDetails = [
                                "password": self.passwordTextField.text!,
                                "email":self.emailTextField.text!,
                                "deviceToken": deviceToken,
                                "deviceId": deviceId
            ]
            
            SignInViewModel().loginServiceViewModel(url: urlString, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                
                //print("Login result: ==> \(String(describing: result))")
                
                //print("Error result: ==> \(String(describing: error))")
                
                
                
                
                if result != nil {
                    
                    self.isSignInTapped = true
                    
                    self.passwordShowHideButton.setImage(UIImage(named: "close"), for: .normal)
                    let authenticationToken = String(describing: result!["authenticationToken"])
                    
                    UserDefaults.standard.set(authenticationToken, forKey: UserdefaultsKeys.authenticationToken.rawValue)
                    let userNameString = String(describing: result!["name"])
                    let keychain = KeychainSwift()
                    let password = "RNCryptorpassword"
                    let enteredPinData = userNameString.data(using: .utf8)
                    let encryptedData = RNCryptor.encrypt(data: enteredPinData!, withPassword: password)
                    keychain.set(encryptedData, forKey: KeychainKeys.userName.rawValue)
                    
                    self.navigateToCreatePinVC()
                    
                } else {
                    self.isSignInTapped = false
                    
//                    self.initializeView()
                    self.fieldValidation()
                    let message = error?.userInfo["ErrorMessage"] as! String
                    self.view.makeToast(message)
//                    let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                    }))
//                    self.present(alert, animated: true, completion: nil)
                }
                
                /*
                 JSON: {
                 authenticationToken = "-VAyEN5pbgqmY6m-ri7El7o4oCkHkHtF";
                 fullname = nagu;
                 message = "Logged in Successfully";
                 status = success;
                 }
                 */
                
            })
        }
            
            /*
            SignInViewModel().loginServiceViewModel(url: urlString, userDetails: userDetails as [String : AnyObject], callback: { (result) in
                //print("Login result: ==> \(result)")
                
                /*
                JSON: {
                    authenticationToken = "-VAyEN5pbgqmY6m-ri7El7o4oCkHkHtF";
                    fullname = nagu;
                    message = "Logged in Successfully";
                    status = success;
                }
                */
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                
                if result["status"] as! String == "success" {
                    self.isSignInTapped = true
                    // set email & pwd ==> close icon
//                    self.errorMessageView.isHidden = true
                    self.passwordShowHideButton.setImage(UIImage(named: "close"), for: .normal)
//                    self.emailCloseButton.isHidden = false
//                    self.errorMessageLabel.text = LOGIN_VALIDATION_ERROR
                    let authenticationToken = result["status"] as! String
                    
                    UserDefaults.standard.set(authenticationToken, forKey: UserdefaultsKeys.authenticationToken.rawValue)
                    
                    let userNameString = result["fullname"] as! String
                    let keychain = KeychainSwift()
                    let password = "RNCryptorpassword"
                    let enteredPinData = userNameString.data(using: .utf8)
                    let encryptedData = RNCryptor.encrypt(data: enteredPinData!, withPassword: password)
                    keychain.set(encryptedData, forKey: KeychainKeys.userName.rawValue)
                    
                    
                    self.navigateToCreatePinVC()
                } else {
                    self.isSignInTapped = false
                    // hide email close icon
                    // change paasword to eye show/hide icon
                    
                    self.initializeView()
                    let message = result["message"] as! String
                    let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                
            })
        }
 */
            
            
        /*
        isSignInTapped = true
        self.errorMessageView.isHidden = false
        passwordShowHideButton.setImage(UIImage(named: "close"), for: .normal)
        self.emailCloseButton.isHidden = false
        self.errorMessageLabel.text = LOGIN_VALIDATION_ERROR
        */
//        self.navigateToCreatePinVC()

        
    }
    
    @IBAction func onTapForgotPassword(_ sender: UIButton) {
        self.initializeView()
        self.setButtonProperties()
        
        self.emailTextField.hideInfo()
        self.passwordTextField.hideInfo()
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let forgotPasswordViewController = storyBoard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
        self.navigationController?.pushViewController(forgotPasswordViewController, animated: true)
 
        
        /*
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.navigationController?.pushViewController(profileViewController, animated: true)
        */
    }
    
    @IBAction func onTapSignUpButton(_ sender: UIButton) {
        self.initializeView()
        self.emailTextField.hideInfo()
        self.passwordTextField.hideInfo()
        self.setButtonProperties()
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let signUpViewController = storyBoard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        self.navigationController?.pushViewController(signUpViewController, animated: true)
        
    }
    
    // MARK: - Tweet TextField Delegates

    @IBAction func emailTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.fieldValidation()
        emailTextField.hideInfo()
    }
    
    @IBAction func emailTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if let emailText = sender.text, Utilities().isValidEmail(emailStr: emailText) == true {
            self.fieldValidation()
            return
        }
        if sender.text == "" {
            sender.showInfo(EMAIL_MANDATORY_ERROR)
        } else {
            sender.showInfo(EMAIL_VALIDATION_ERROR)
        }
    }
    
    @IBAction func passwordTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.fieldValidation()
        sender.hideInfo()
    }
    
    @IBAction func passwordTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
       
        if sender.text == "" {
            sender.showInfo(PASSWORD_MANDATORY_ERROR)
        } else {
            self.fieldValidation()
            return
        }
        
        
        /*
        if isValidPassword(passwordStr: sender.text!) {
            self.fieldValidation()
            return
        }
        if sender.text == "" {
            sender.showInfo(PASSWORD_MANDATORY_ERROR)
        }
 */

        /*else if (sender.text?.count)! > 8 {
            sender.showInfo(PASSWORD_VALIDATION_ERROR)
        } else {
            sender.showInfo(PASSWORD_VALIDATION_ERROR)
        } */
        
        
        
    }
    
    // MARK: - Validation Methods
    
    func isValidPassword(passwordStr: String) -> Bool {
//        let passwordRegEx = "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z])(?=.*[!@#$%&*()-.,]).{8,16}$"
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%&*().,])[A-Za-z\\d!@#$%&*().,]{8,16}"
        let passwordTest = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordTest.evaluate(with: passwordStr)
    }
    
}

    // MARK: - UIScrollViewDelegate

    extension SignInViewController: UIScrollViewDelegate {
        // scroll view delegate methods
        
    }





// MARK: - UITextFieldDelegate

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
//        lastOffset = self.scrollView.contentOffset
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.passwordTextField {
            if(textField.text?.count)! < 16 {
                return true
                
            } else if(string == "") {
                
                //print("Backspace pressed");
                return true;
                
            } else {
                return false
            }
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        activeField?.resignFirstResponder()
        activeField = nil
        return true
    }
}

