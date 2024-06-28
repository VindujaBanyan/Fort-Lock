//
//  TransferOwnerViewController.swift
//  SmartLockiOS
//
//  Created by Vanithasree Singaravelu on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Contacts
import ContactsUI
import SlideMenuControllerSwift
import UIKit
import SKCountryPicker

class TransferOwnerViewController: UIViewController, CNContactPickerDelegate {
    // Outlets
    @IBOutlet var titleLbl: UILabel!
    @IBOutlet var personContainerView: UIView!
    @IBOutlet var personNameLbl: UILabel!
    @IBOutlet var roleLbl: UILabel!
    @IBOutlet var addOrContiuneBtn: UIButton!
    @IBOutlet weak var phoneNumberConfirmView: MobileNumberConfirmView!
    @IBOutlet weak var shadowView: UIView!
    lazy var country = Country(countryCode: "IN")

    var bluetoothAdvertisment:BluetoothAdvertismentData?
    // Variables
    var isAddScreen = Bool()
    var contactPhoneArray: NSMutableArray = []
    
    var transferKeyId = String()
    var userLockID = String()
    var isWithdrawEnabled = Bool()
    var requestID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        getAssignUserKeyList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isAddScreen {
            setAddScreenObjects()
        } else {
            setContactChoosenScreenObjects(newOwnerDetailsArray: [])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        addBackBarButton()
        title = "Transfer Owner"
        self.updateFont()
        navigationItem.setHidesBackButton(true, animated: true)
        Utilities().setButtonProperties(button: addOrContiuneBtn)
        phoneNumberConfirmView.controller = self
        self.showMobileNumberConfirmView(hidden: true)
        phoneNumberConfirmView.btnCancelActionClosure = {
            self.showMobileNumberConfirmView(hidden: true)
        }
        phoneNumberConfirmView.btnConfirmActionClosure = {countryCode,phoneNumber in
            self.showMobileNumberConfirmView(hidden: true)
            print(countryCode)
            print(phoneNumber)
            self.createTransferOwnerService(selectedMobile: phoneNumber, countryCode: countryCode)
        }
    }
    
    func updateFont() {
        self.titleLbl.font = UIFont.setRobotoRegular17FontForTitle
        self.personNameLbl.font = UIFont.setRobotoRegular17FontForTitle
        self.roleLbl.font = UIFont.setRobotoRegular14FontForTitle
        addOrContiuneBtn.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
    }
    
    // MARK: - Navigation Bar Button
    
    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(popToViewController), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    // MARK: - UIButton Actions
    
    @IBAction func onTapAddOrContinueBtn(_ sender: Any) {
        if isAddScreen {
            openContactPickerViewController()
        } else {
            // navigate to dashboard
            
            if isWithdrawEnabled {
                self.withdrawTranferOwner(requestId: requestID)
            } else {
                loadMainView()
            }
        }
    }
    
    @objc func popToViewController() {
        navigationController!.popViewController(animated: false)
    }
    
    // MARK: - Contact Delegates
    
    func openContactPickerViewController() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        present(contactPicker, animated: true, completion: nil)
    }
    
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        //print(contact)
        contactPhoneArray.removeAllObjects()
        for phoneNumber in contact.phoneNumbers {
            let dictParams: NSMutableDictionary? = ["PersonName": contact.givenName,
                                                    "PersonNumber": (phoneNumber.value).value(forKey: "stringValue") as Any,"CountryCode": (phoneNumber.value).value(forKey: "countryCode") as Any
            ]
            //            contactPhoneArray.add(dictParams as Any)
            let phNumber = (phoneNumber.value).value(forKey: "stringValue")
            if !Utilities.isNilOrEmptyString(string: phNumber as! String) {
                contactPhoneArray.add(dictParams as Any)
            }
            //print("The \(String(describing: phoneNumber.label)) number of \(contact.givenName) is: \(phoneNumber.value)")
            //print(contactPhoneArray)
        }
        picker.dismiss(animated: true) {
            if self.contactPhoneArray.count > 1 {
                self.showUserContactsListAlert(phoneListArray: self.contactPhoneArray)
            } else {
                if self.contactPhoneArray.count > 0 {
                    let contactDetails = self.contactPhoneArray[0] as! NSDictionary
                    self.showConfirmDialog(selectedMobile: contactDetails["PersonNumber"] as! String, countryCode: contactDetails["CountryCode"] as? String)
                } else {
                    let alert = UIAlertController(title: ALERT_TITLE, message: INVALID_CONTACT_SELECTION, preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Show Contacts List
    
    @objc func showUserContactsListAlert(phoneListArray: NSMutableArray) {
        //  let topVC = topMostController()
        let getPersonName = phoneListArray[0] as! NSDictionary
        let alert = UIAlertController(title: getPersonName["PersonName"] as? String, message: "Select your phone number", preferredStyle: UIAlertController.Style.alert)
        for i in 0...(phoneListArray.count - 1) {
            let personNumber = phoneListArray[i] as! NSDictionary
            //print("person num ==> \(personNumber)")
            //print("person num ==> \(String(describing: personNumber["PersonNumber"]))")
            alert.addAction(UIAlertAction(title: personNumber["PersonNumber"] as? String, style: .default, handler: { action in
                let personNumberString = action.title
                //print(personNumberString as Any)
                //                self.showConfirmDialog(choosenContactDetailArray: [])
                self.showConfirmDialog(selectedMobile: personNumberString! as String, countryCode: personNumber["CountryCode"] as? String)
                
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Show confirm alert
    
    func showConfirmDialog(selectedMobile: String, countryCode:String?) {
        let alertController = UIAlertController(title: "Transfer Owner", message: "Do you want to confirm to change the lock owner?", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "OK", style: .default) { (_: UIAlertAction) in
            //print("You've pressed Ok")
            self.country = Country.init(countryCode: countryCode?.uppercased() ?? "US")
            self.phoneNumberConfirmView.country = self.country
            self.phoneNumberConfirmView.phoneNumber = selectedMobile
            self.phoneNumberConfirmView.setValues()
            self.showMobileNumberConfirmView(hidden: false)
//            self.createTransferOwnerService(selectedMobile: selectedMobile)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (_: UIAlertAction) in
            //print("You've pressed cancel")
        }
        alertController.addAction(action1)
        alertController.addAction(action2)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Check ViewController Hierarchy
    
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while topController.presentedViewController != nil {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    // MARK: - Add Screen Objects
    
    func setAddScreenObjects() {
        titleLbl.text = "Transfer to new owner"
        personContainerView.isHidden = true
        personNameLbl.text = " "
        roleLbl.text = " "
        /*  if Utilities.isNilOrEmptyString(string: nil) {
         roleLbl.text = "Empty"
         }*/
        
        addOrContiuneBtn.setTitle("ADD", for: .normal)
    }
    
    // MARK: - Contact Choosen Screen Objects
    
    func setContactChoosenScreenObjects(newOwnerDetailsArray: NSMutableArray) {
        titleLbl.text = "Transfer to new owner request has been sent successfully"
        personContainerView.isHidden = false
        personNameLbl.text = "New owner's name"
        roleLbl.text = "User 25"
        addOrContiuneBtn.setTitle("CONTINUE", for: .normal)
    }
    
    func updateContactChoosenScreenObjects(newOwner: String) {
        titleLbl.text = "Transfer to new owner request has been sent successfully"
        personContainerView.isHidden = false
        personNameLbl.text = newOwner
        roleLbl.text = "New Owner"
        addOrContiuneBtn.setTitle("CONTINUE", for: .normal)
    }
    
    // MARK: - Service Call
    
    @objc func getAssignUserKeyList() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        //        keys/keylist?id=id&owner=owner
        let ownerStatus = "1"
        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(userLockID)&owner=\(ownerStatus)"
        //        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)"
        
        TransferOwnerViewModel().getAssignUserKeyListServiceViewModel(url: urlString, userDetails: [:]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                let resultObj1 = result![0] as! AssignUserModel
                let userID1 = resultObj1.userId
                
                let resultObj2 = result![1] as! AssignUserModel
                let userID2 = resultObj2.userId
                
                var requestedToUserName = ""
                /*
                if resultObj1.requestDetails != nil {
                    if resultObj1.userDetails != nil {
                        if resultObj1.userDetails.username != nil {
                            requestedToUserName = resultObj1.userDetails.username
                        }
                    }
                    
                } else if resultObj2.requestDetails != nil {
                    if resultObj2.userDetails != nil {
                        if resultObj2.userDetails.username != nil {
                            requestedToUserName = resultObj2.userDetails.username
                        }
                    }
                } else {
                }
 
 */
                
                if resultObj1.status == "0" {
                    
                    
                    if resultObj1.userDetails != nil {
                        if resultObj1.userDetails.username != nil {
                            requestedToUserName = resultObj1.userDetails.username
                        }
                    }
                    
                    if resultObj1.requestDetails != nil {
                        if resultObj1.requestDetails.id != nil {
                            self.requestID = resultObj1.requestDetails.id
                        }
                    }

                    
                } else if resultObj2.status == "0" {
                    if resultObj2.userDetails != nil {
                        if resultObj2.userDetails.username != nil {
                            requestedToUserName = resultObj2.userDetails.username
                        }
                    }
                    if resultObj2.requestDetails != nil {
                        if resultObj2.requestDetails.id != nil {
                            self.requestID = resultObj2.requestDetails.id
                        }
                    }
                } else {
                }
                
                // status 0 ==> new owner
                
                if userID1 != "" && userID2 != "" {
                    // transfer owner initiated
                    
                    self.isAddScreen = false
                    //                self.setContactChoosenScreenObjects(newOwnerDetailsArray: [])
                    self.titleLbl.text = "Transfer to new owner request has been sent successfully"
                    self.personContainerView.isHidden = false
                    self.personNameLbl.text = requestedToUserName
                    self.roleLbl.text = "New Owner"
                    self.addOrContiuneBtn.setTitle("WITHDRAW", for: .normal)
//                    self.navigationItem.leftBarButtonItem = nil
                    self.isWithdrawEnabled = true
                } else {
                    self.isWithdrawEnabled = false
                }
                
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
    
    func createTransferOwnerService(selectedMobile: String, countryCode:String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "requests/createrequest"
        
        var mobNumber = selectedMobile.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        //print("mobNumber ==> \(mobNumber)")
        
        // key list ==> use "id" from owner id with user_id null
        
        let userDetailsDict = ["key_id": self.transferKeyId, 
                               "mobile": mobNumber,
                               "status": "0","country_code":countryCode]
        
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
        
        TransferOwnerViewModel().createTransferOwnerRequestUserServiceViewModel(url: urlString, userDetails: userDetails as [String: String]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                let resultArray = result as! [AssignUserDetailsModel]
                let userDetailsObj = result![0] as! AssignUserDetailsModel
                self.isAddScreen = false
                self.updateContactChoosenScreenObjects(newOwner: userDetailsObj.username!)
                self.navigationItem.leftBarButtonItem = nil
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
                self.setAddScreenObjects()
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//                
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                    self.setAddScreenObjects()
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    func withdrawTranferOwner(requestId: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        
//        http://smart-app-qa.payoda.com/api/web/v1/requests/updaterequest?id=12

        let urlString = ServiceUrl.BASE_URL + "requests/updaterequest?id=\(requestId)"
        
        let userDetailsDict = [
            "status": "3",
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
        
        TransferOwnerViewModel().withdrawTransferOwnerRequestUserServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                self.loadMainView()
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
    
    
    // MARK: - Navigation methods
    
    fileprivate func loadMainView() {
        // create viewController code...
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        leftViewController.mainViewController = navigationController
        
        let slider = SlideMenuController(mainViewController: navigationController, leftMenuViewController: leftViewController)
        
        slider.automaticallyAdjustsScrollViewInsets = true
        slider.delegate = mainViewController
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = slider
        appDelegate.window?.makeKeyAndVisible()
    }
}


/// Country code selection and validation
extension TransferOwnerViewController {
    func showMobileNumberConfirmView(hidden : Bool){
        CountryManager.shared.resetLastSelectedCountry()
        self.shadowView.isHidden = hidden
        self.phoneNumberConfirmView.isHidden = hidden
    }
}
