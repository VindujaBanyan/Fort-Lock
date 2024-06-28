//
//  ForgotPasswordViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 29/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {
    @IBOutlet var forgotPasswordView: UIView!
    @IBOutlet var emailTextField: TweeAttributedTextField!
    
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var signUpButton: UIButton! // 18
    
    @IBOutlet var successView: UIView!
    @IBOutlet var instructionLabel: UILabel!
    
    @IBOutlet weak var successTextLabel: UILabel! // 29
    @IBOutlet weak var forgotPasswordTextLabel: UILabel! // 29

    @IBOutlet weak var forgotPasswordInstructionLabel: UILabel! // 17
    
    
    
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        title = "Forgot Password"
        self.addBackBarButton()
        self.setButtonProperties()
        self.updateTextFont()
    }
    
    
    func updateTextFont() {
        emailTextField.font = UIFont.setRobotoRegular14FontForTitle
        forgotPasswordInstructionLabel.font = UIFont.setRobotoRegular18FontForTitle
        
        instructionLabel.font = UIFont.setRobotoRegular18FontForTitle
        
        successTextLabel.font = UIFont.setRobotoRegular29FontForTitle
        forgotPasswordTextLabel.font = UIFont.setRobotoRegular29FontForTitle
        
        sendButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
        signUpButton.titleLabel?.font = UIFont.setRobotoMedium18FontForTitle
    }
    
    func setButtonProperties() {
        self.sendButton.layer.cornerRadius = 5.0
        self.sendButton.layer.masksToBounds = true
        self.sendButton.isEnabled = false
        self.sendButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.8)
        //        self.sendButton.isUserInteractionEnabled = false
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
    
    // MARK: - TextField Delegates
    
    @IBAction func emailTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        emailTextField.hideInfo()
    }
    
    @IBAction func emailTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if let emailText = sender.text, Utilities().isValidEmail(emailStr: emailText) == true {
            self.sendButton.isEnabled = true
            self.sendButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
//            self.sendButton.isUserInteractionEnabled = true
            return
        }
        
        self.sendButton.isEnabled = false
        self.sendButton.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
        
        if sender.text == "" {
            sender.showInfo(EMAIL_MANDATORY_ERROR)
        } else {
            sender.showInfo(EMAIL_VALIDATION_ERROR)
        }
        
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapSendButton(_ sender: UIButton) {
        if emailTextField.text == "" {
            /*
            let alertController = UIAlertController(title: EMAIL_MANDATORY_ERROR, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
 */
            
        } else {
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            
            let urlString = ServiceUrl.BASE_URL + "users/forgotpassword"
            
            /*
             {
             "email":"sps@payoda.com"
             }

             */
            
            let userDetails = [
                                "email":self.emailTextField.text!
            ]
            ForgotPasswordViewModel().forgotPasswordServiceViewModel(url: urlString, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.navigationController?.navigationBar.isUserInteractionEnabled = true

                //print("Result ==> \(result)")
              //  if result != nil {
                if let result = result  {
                    // On service call success navigate to success screen
                    self.forgotPasswordView.isHidden = true
                    self.successView.isHidden = false
                    self.instructionLabel.text = "An email with a reset password link has been sent to the email address, " + self.emailTextField.text! + ". Please reset your password to proceed."
                        
//                        "An email has been sent to your rescue email address, " + self.emailTextField.text! + ". Follow the direction in the email to reset your password"
                    
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
             
             ForgotPasswordViewModel().forgotPasswordServiceViewModel(url: urlString, userDetails: userDetails as [String : AnyObject], callback: { (result) in
             
             LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
             
             //print("Result ==> \(result)")
             if result["status"] as! String == "success" {
             // On service call success navigate to success screen
             self.forgotPasswordView.isHidden = true
             self.successView.isHidden = false
             self.instructionLabel.text = "An email with a reset password link has been sent to the email address, " + self.emailTextField.text! + ". Please reset your password to proceed."
             
             //                        "An email has been sent to your rescue email address, " + self.emailTextField.text! + ". Follow the direction in the email to reset your password"
             
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
    
    @IBAction func onTapSignUpButton(_ sender: UIButton) {
        self.emailTextField.text = ""
        self.emailTextField.hideInfo()
        self.setButtonProperties()
        
        let signUpViewController = storyBoard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        signUpViewController.isFromForgotPassword = true
        navigationController?.pushViewController(signUpViewController, animated: true)
    }
    
    @objc func popToViewController() {
        self.navigationController! .popViewController(animated: false)
    }
}
