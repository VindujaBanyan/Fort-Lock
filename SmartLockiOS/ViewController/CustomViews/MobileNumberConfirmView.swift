//
//  MobileNumberConfirmView.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 16/11/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
import SKCountryPicker
import libPhoneNumber_iOS


class MobileNumberConfirmView: UIView {
    
    @IBOutlet weak var mobileNumberConfirmView: UIView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    @IBOutlet weak var countryCodeButton: UIButton!
    @IBOutlet weak var mobileTextField: TweeAttributedTextField!
    @IBOutlet weak var lblConfirmMobileNumber: UILabel!
    lazy var country = Country(countryCode: "IN")
    var controller = UIViewController()
    @IBOutlet var contentView: UIView!
    var btnCancelActionClosure: (() -> Void)?
    var btnConfirmActionClosure: ((_ countryCode : String,_ phoneNumber : String) -> Void)?
    lazy var phoneNumber = String()



    override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            commonInit()
        }
        
        func commonInit() {
            Bundle.main.loadNibNamed("MobileNumberConfirmView", owner: self, options: nil)
            contentView.fixInView(self)
            self.disableSignUpButton()
        }
    
    func setValues() {
        self.mobileTextField.text = ""
        self.lblConfirmMobileNumber.text = "Please confirm this mobile number : \(phoneNumber)"
        self.countryCodeButton.setTitle(self.country.dialingCode, for: .normal)
        self.countryCodeButton.setImage(self.country.flag, for: .normal)
    }
    
    
//    fileprivate init() {
//        super.init(frame: UIScreen.main.bounds)
//        self.commonInit()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    func commonInit() {
//            Bundle.main.loadNibNamed("MobileNumberConfirmView", owner: self, options: nil)
//        mobileNumberConfirmView.fixInView(self)
//        }

}


/// Country code selection and validation
extension MobileNumberConfirmView {
    
    @IBAction func btnCountryCodeAction(_ sender: Any) {
        presentCountryPickerScene(withSelectionControlEnabled: true)
    }
    /// Dynamically presents country picker scene with an option of including `Selection Control`.
    ///
    /// By default, invoking this function without defining `selectionControlEnabled` parameter. Its set to `True`
    /// unless otherwise and the `Selection Control` will be included into the list view.
    ///
    /// - Parameter selectionControlEnabled: Section Control State. By default its set to `True` unless otherwise.
    
//    func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
//        let countryController: UIViewController
//        switch selectionControlEnabled {
//        case true:
//            // Present country picker with `Section Control` enabled
//            let countryController = CountryPickerWithSectionViewController.presentController(on: controller) { [weak self] (country: Country) in
//                
//                guard let self = self else { return }
//                self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
//                self.countryCodeButton.setImage(country.flag, for: .normal)
//                self.country = country
//                self.validation()
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
//            let countryController = CountryPickerController.presentController(on: controller) { [weak self] (country: Country) in
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
    func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
        // Declare countryController outside of the switch statement
       // let countryController: UIViewController
        
        switch selectionControlEnabled {
        case true:
            // Present country picker with `Section Control` enabled
              let countryController = CountryPickerWithSectionViewController.presentController(on: controller) { [weak self] (country: Country) in
                guard let self = self else { return }
                self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
                self.countryCodeButton.setImage(country.flag, for: .normal)
                self.country = country
                self.validation()
            }
            
            // Configure properties and methods specific to CountryPickerWithSectionViewController
            if let pickerController = countryController as? CountryPickerWithSectionViewController {
                pickerController.configuration.flagStyle = .circular
                pickerController.configuration.isCountryFlagHidden = false
                pickerController.configuration.isCountryDialHidden = false
                // pickerController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
            }
            
        case false:
            // Present country picker without `Section Control` enabled
           let countryController = CountryPickerController.presentController(on: controller) { [weak self] (country: Country) in
                
                guard let self = self else { return }
                
                self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
                self.countryCodeButton.setImage(country.flag, for: .normal)
                self.country = country
            }
            
            // Configure properties and methods specific to CountryPickerController
            if let pickerController = countryController as? CountryPickerController {
                pickerController.configuration.flagStyle = .corner
                pickerController.configuration.isCountryFlagHidden = false
                pickerController.configuration.isCountryDialHidden = false
                // pickerController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]
            }
        }
    }

    
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
    @IBAction func btnCancelAction(_ sender: Any) {
        btnCancelActionClosure?()
//        self.showMobileNumberConfirmView(hidden: true)
    }
    @IBAction func btnConfirmAction(_ sender: Any) {
        btnConfirmActionClosure?(country.countryCode, mobileTextField.text ?? "")
//        self.showMobileNumberConfirmView(hidden: true)
    }
    func showMobileNumberConfirmView(hidden : Bool){
        mobileNumberConfirmView.isHidden = hidden
    }
    @IBAction func mobileTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.disableSignUpButton()
        mobileTextField.hideInfo()
    }
    @IBAction func mobileTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        
        if mobileNumberValidationCheck() {
            if sender.text == "0000000000" {
               sender.showInfo(MOBILE_VALIDATION_ERROR)
                self.disableSignUpButton()
            } else {
                self.enableSignUpButton()
                return
            }
        }else {
            sender.showInfo(MOBILE_VALIDATION_ERROR)
            self.disableSignUpButton()
        }
    }
    func disableSignUpButton(){
        self.btnConfirm.isEnabled = false
        self.btnConfirm.isUserInteractionEnabled = false
        self.btnConfirm.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 0.5)
    }
    func enableSignUpButton(){
        self.mobileTextField.hideInfo()
        self.btnConfirm.isUserInteractionEnabled = true
        self.btnConfirm.isEnabled = true
        self.btnConfirm.backgroundColor = UIColor(red: 254/255, green: 158/255, blue: 67/255, alpha: 1.0)
    }
    func validation() {
        self.disableSignUpButton()
        var errorMessage = ""
         if (self.mobileTextField.text?.isEmpty)! {
            errorMessage = MOBILE_MANDATORY_ERROR
            self.mobileTextField.showInfo(errorMessage)
        } else if !(self.mobileNumberValidationCheck()) {
            errorMessage = MOBILE_VALIDATION_ERROR
            self.mobileTextField.showInfo(errorMessage)
        } else {
            self.enableSignUpButton()
        }
    }
}


extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
