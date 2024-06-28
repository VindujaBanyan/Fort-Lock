//
//  FPNewUserViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/7/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class FPNewUserViewController: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var nameTextField: TweeAttributedTextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var isAddUser = Bool()
    var isEditUser = Bool()
    var userRegistrationObj = RegistrationDetailsModel()
    var lockId = String()
    var scratchCode = String()
    var lockConnection:LockConnection = LockConnection()
    var lockListDetailsObj = LockListModel(json: [:])
    
    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize method
    func initialize() {
        title = "Add Finger Print"
        addBackBarButton()
        setMainViewUI()
        setTextfieldProperties()
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
    
    // MARK: - UI update methods
    
    /// Set mainView UI
    func setMainViewUI() {
        
        mainView.layer.cornerRadius = 10
        mainView.clipsToBounds = true
        mainView.layer.shadowColor = UIColor.gray.cgColor
        mainView.layer.shadowOpacity = 1
        mainView.layer.shadowOffset = CGSize(width: 3, height: 3)
        mainView.layer.shadowRadius = 10
        mainView.layer.shadowPath = UIBezierPath(rect: mainView.bounds).cgPath
        mainView.layer.shouldRasterize = true
        mainView.layer.masksToBounds = false
    }
    
    /// Set nameTextField properties
    func setTextfieldProperties() {
        if isAddUser {
            setNextButtonProperties(status: false)
            nameTextField.resignFirstResponder()
            nameTextField.text = ""
        }
        if isEditUser {
            setNextButtonProperties(status: true)
            nameTextField.text = userRegistrationObj.name
            nameTextField.becomeFirstResponder()
        }
        nameTextField.hideInfo()
        nameTextField.textColor = UIColor.black
        nameTextField.delegate = self
    }
    
    /// Set nextButton properties with status
    /// - Parameter status: Bool value
    func setNextButtonProperties(status: Bool) {
        self.nextButton.isEnabled = status
        self.nextButton.isUserInteractionEnabled = status
        self.nextButton.backgroundColor = status ? UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 1.0) : UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 0.6)
    }
        
    // MARK: - Button Actions
    
    /// Pop to UIViewController
    @objc func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
    
    /// Nex button action
    /// - Parameter sender: Button instance
    @IBAction func onTapNextButton(_ sender: UIButton) {
        if isAddUser {
            // after validation navigate to add fp screen
            navigateToCustomAddViewController()
        }
        if isEditUser {
            // after validation navigate to back screen
            editUserNameServiceCall()
        }
    }
    
    // MARK: - Validation
    
    /// Do nameTextField validation
       func validation() {
           if (self.nameTextField.text?.isEmpty)! {
                setNextButtonProperties(status: false)
           } else {
               setNextButtonProperties(status: true)
           }
       }
    
    // MARK: - Navigation Methods
    
    func navigateToCustomAddViewController() {
        let customAddViewController = storyBoard.instantiateViewController(withIdentifier: "CustomAddViewController") as! CustomAddViewController
        customAddViewController.isFromRFIDScreen = false
        customAddViewController.isFromFingerPrintScreen = true
        customAddViewController.isAlreadyFingerPrintAssigned = false
        customAddViewController.lockId = self.lockId
        customAddViewController.guestUserName = self.nameTextField.text ?? ""
        customAddViewController.userID = "" // Guest user didnt have user id before FP added
        customAddViewController.lockConnection.selectedLock =  lockConnection.selectedLock
        customAddViewController.lockConnection.serialNumber = lockConnection.serialNumber
        customAddViewController.scratchCode = scratchCode
        customAddViewController.lockListDetailsObj = self.lockListDetailsObj
        self.navigationController?.pushViewController(customAddViewController, animated: true)
    }
}

// MARK: - TextField Methods
extension FPNewUserViewController {
    
    @IBAction func nameDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        nameTextField.hideInfo()
    }
    
    @IBAction func nameDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text == "" {
            sender.showInfo(NAME_MANDATORY_ERROR)
        } else {
            self.validation()
            return
        }
    }
}

// MARK: - UITextFieldDelegate

extension FPNewUserViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.nameTextField {
            if (string.rangeOfCharacter(from: NSCharacterSet.letters) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) && (textField.text?.count)! < 50    {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                if textField.text?.count == 0 {
                    setNextButtonProperties(status: true)
                } else {
                    validation()
                }
                return true
            } else if string == "" { //"Backspace pressed"
                if textField.text?.count == 1 {
                    setNextButtonProperties(status: false)
                }
                return true
            } else {
                return false
            }
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}


// MARK: -  Service call

extension FPNewUserViewController {
    
    /// Edit guset user service call
    func editUserNameServiceCall() {    
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/updateguestname"
        
        let userDetailsDict = [
            "id": userRegistrationObj.id, // Registration id
            "name": self.nameTextField.text // registration name
            ]
        
        var userDetails = [String: String]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictFromJSON = decoded as? [String: String] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        FPViewModel().updateUserNameServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                self.navigationController?.popViewController(animated: false)
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//                
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
