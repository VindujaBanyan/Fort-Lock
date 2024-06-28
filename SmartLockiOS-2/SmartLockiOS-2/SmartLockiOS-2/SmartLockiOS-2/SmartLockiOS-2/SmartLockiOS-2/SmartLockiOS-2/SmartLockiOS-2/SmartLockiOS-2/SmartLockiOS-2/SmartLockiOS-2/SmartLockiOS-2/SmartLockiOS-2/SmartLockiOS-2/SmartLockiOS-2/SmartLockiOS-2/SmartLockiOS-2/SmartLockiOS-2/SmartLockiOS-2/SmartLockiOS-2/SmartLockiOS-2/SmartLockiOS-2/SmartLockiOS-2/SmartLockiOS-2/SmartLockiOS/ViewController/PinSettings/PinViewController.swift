//
//  PinViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 30/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class PinViewController: UIViewController {

    weak var delegate: LeftMenuProtocol?

    var customBackBtnItem = UIBarButtonItem()
    
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var securityPinView: UIView!
    
    @IBOutlet weak var successStatusLabel: UILabel!
    @IBOutlet weak var successView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var button5: UIButton!
    @IBOutlet weak var button6: UIButton!
    @IBOutlet weak var button7: UIButton!
    @IBOutlet weak var button8: UIButton!
    @IBOutlet weak var button9: UIButton!
    @IBOutlet weak var button0: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    let numberOfPinDigits = 4
    var numberOfDigitsEntered = 0
    
    var isFirstPin: Bool = true
    var isFromResetPIN = Bool()
    var isFromLogin = Bool()
    
    let bulletCharacter: String = "\u{25CF}"
    let dashCharacter: String = "\u{2010}"
    
    ////////////////////////
    var labelsArray: [UILabel] = []
//    var pinTextField = UITextField()
    var enteredPin: String = ""
    var enteredConfirmPin: String = ""
    var isFromSettings = Bool()
    var isFromValidation = Bool()
    var launchType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
//        self.setNavigationBarItem()
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        coordinator.animate(alongsideTransition: nil, completion: { (context: UIViewControllerTransitionCoordinatorContext!) -> Void in
//            guard let vc = (self.slideMenuController()?.mainViewController as? UINavigationController)?.topViewController else {
//                return
//            }
//            if vc.isKind(of: NonMenuController.self)  {
//                self.slideMenuController()?.removeLeftGestures()
//                self.slideMenuController()?.removeRightGestures()
//            }
//        })
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize methods
    
    func initialize() {
        self.title = "Security PIN"
        self.updateTextFont()
        self.createPinView()
        self.updateButtonProperties()
        self.instructionLabel.text = "Create and set your New PIN"
        if isFromLogin {
            self.instructionLabel.text = "Create and set your Security PIN"
            self.cancelButton.isHidden = true
        }
        self.navigationItem.setHidesBackButton(true, animated:true)

        self.addBackBarButton()
        self.navigationItem.leftBarButtonItem = nil
        
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.layer.cornerRadius = 5.0
        self.continueButton.layer.masksToBounds = true
        
//        self.navigationItem.setHidesBackButton(true, animated:true);
    }
    
    func updateTextFont() {
        self.successStatusLabel.font = UIFont.setRobotoRegular25FontForTitle
        self.instructionLabel.font = UIFont.setRobotoRegular17FontForTitle
        
        self.cancelButton.titleLabel?.font = UIFont.setRobotoRegular20FontForTitle
        self.deleteButton.titleLabel?.font = UIFont.setRobotoRegular20FontForTitle
        self.continueButton.titleLabel?.font = UIFont.setRobotoRegular25FontForTitle
    }
    
    func addBackBarButton() {
        
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToRoot), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        customBackBtnItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    @objc func popToRoot() {
            isFirstPin = !isFirstPin
            self.initializePinView()
            enteredConfirmPin = ""
            self.navigationItem.leftBarButtonItem = nil
//            self.navigationItem.setHidesBackButton(true, animated:true)
            self.isFirstPin = true
            self.initializePinView()
            self.enteredPin = ""
            self.enteredConfirmPin = ""
            self.numberOfDigitsEntered = 0
            self.instructionLabel.text = "Create and set your New PIN"
            if isFromLogin {
                self.instructionLabel.text = "Create and set your Security PIN"
                self.cancelButton.isHidden = true
            }
    }
    
    //MARK: - PIN View Creation
    
    func createPinView() {
        /*
        //TextField for displaying keyboard
        pinTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        pinTextField.hidden = true
        pinTextField.delegate = self
        pinTextField.keyboardType = .NumberPad
        pinTextField.becomeFirstResponder()
        self.pinView.addSubview(pinTextField)
        */
        
        //Pin label creation
        var xPos = 0
        let labelWidthHeight = 50
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        
        for _ in 0...numberOfPinDigits - 1 {
            
            let pinLabel = UILabel(frame: CGRect(x: xPos, y: 0, width: labelWidthHeight, height: labelWidthHeight))
            pinLabel.font = UIFont.systemFont(ofSize: 25.0)
            pinLabel.textAlignment = .center
            pinLabel.text = dashCharacter
            pinLabel.textColor = .white
            
            labelsArray.append(pinLabel)
            contentView.addSubview(pinLabel)
            xPos = xPos + labelWidthHeight
        }
        self.pinView.addSubview(contentView)
    }
    
    func initializePinView() {
        for i in 0...labelsArray.count - 1 {
            let passedLabel = labelsArray[i] as UILabel
            passedLabel.text = dashCharacter
        }
    }
    
    func updateLabelValue(index: Int, value: String) {
        
        var valueStr = ""
        var indexv = index
        
        if value == "" {
            indexv = index - 1
            valueStr = dashCharacter
        } else {
            valueStr = bulletCharacter
        }
        
        if indexv < labelsArray.count {
            let passedLabel = labelsArray[indexv] as UILabel
            passedLabel.text = valueStr
        }
    }
    
    // MARK: - Button Properties
    
    func setButtonProperties(button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = button.frame.size.width/2.0
        button.layer.masksToBounds = true
    }
    
    func updateButtonProperties()  {
        self.setButtonProperties(button: self.button0)
        self.setButtonProperties(button: self.button1)
        self.setButtonProperties(button: self.button2)
        self.setButtonProperties(button: self.button3)
        self.setButtonProperties(button: self.button4)
        self.setButtonProperties(button: self.button5)
        self.setButtonProperties(button: self.button6)
        self.setButtonProperties(button: self.button7)
        self.setButtonProperties(button: self.button8)
        self.setButtonProperties(button: self.button9)
    }
    
    //MARK: - Validation Methods

    func onPressPin(text: String) {
        numberOfDigitsEntered += 1
        
        //print("=========================")
        //print("numberOfDigitsEntered ==> \(numberOfDigitsEntered)")
        //print("numberOfPinDigits ==> \(numberOfPinDigits)")
       

        if numberOfDigitsEntered == numberOfPinDigits {
            self.updateLabelValue(index: numberOfDigitsEntered-1, value: text)
            

            //print("done")
            
            if isFirstPin {
                enteredPin = enteredPin + text
                //print("enteredPin ==> \(enteredPin)")
                self.isFirstPin = false
                //            self.navigationItem.setHidesBackButton(false, animated:true);
                self.navigationItem.leftBarButtonItem = self.customBackBtnItem
                self.initializePinView()
                self.numberOfDigitsEntered = 0
                
                self.instructionLabel.text = "Confirm the New PIN"
                if isFromLogin {
                    self.instructionLabel.text = "Confirm the Security PIN"
                }
                
                //self.showPinAlert(title: "Alert", message: "Are you sure you want to use this PIN?")
            } else {
//                verify pin
                enteredConfirmPin = enteredConfirmPin + text
                //print("enteredConfirmPin ==> \(enteredConfirmPin)")
                
                if enteredPin == enteredConfirmPin {
                     // save in keychain and navigate to dashboard
                    
                    let keychain = KeychainSwift()
                    keychain.set(enteredPin, forKey: KeychainKeys.securityPin.rawValue)
                    let a = keychain.get(KeychainKeys.securityPin.rawValue)
                    //print("securityPIN ==> \(String(describing: a!))")
                    
                    let password = "RNCryptorpassword"
                    let enteredPinData = enteredPin.data(using: .utf8)
                    let encryptedData = RNCryptor.encrypt(data: enteredPinData!, withPassword: password)
                    keychain.set(encryptedData, forKey: KeychainKeys.securityPin.rawValue)
                    
                    let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
                    do {
                        let decryptData = try RNCryptor.decrypt(data: decryptValue!, withPassword: password)
                        let decryptedPINString = String(decoding: decryptData, as: UTF8.self)
                        //print("securityPIN ==> \(String(describing: decryptedPINString))")
                        
                        // ...
                    } catch {
                        //print(error)
                    }
                    
                    /*
                    if isFromResetPIN {
                        // ?
                        self.loadMainView()
                      
//                         self.navigationController?.popToRootViewController(animated: true)
//self.navigationController?.dismiss(animated: true, completion: nil)
//                        delegate?.changeViewController(LeftMenu.main)
                    } else {
                        // navigate to main view controller
                        self.navigateToDashboard()
                    }*/
                    
                    
                    var alertMessage = "Security Pin updated successfully"
                    
                    if isFromLogin {
                        alertMessage = "Security Pin set successfully"
                    }
                    
                    /*
                    let alert = UIAlertController(title: ALERT_TITLE, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.loadMainView()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    */
                    self.navigationItem.leftBarButtonItem = nil
                    self.securityPinView.isHidden = true
                    self.successView.isHidden = false
                    self.successStatusLabel.text = alertMessage
                    
                    
                }  else {
                    
                    let alert = UIAlertController(title:"New PIN and confirm PIN doesn't match", message: "", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.enteredConfirmPin = ""
                        self.numberOfDigitsEntered = 0
                        self.initializePinView()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
            }
            
        } else if numberOfDigitsEntered < numberOfPinDigits {
            
            if isFirstPin {
                enteredPin = enteredPin + text
            } else {
                //                verify pin
                enteredConfirmPin = enteredConfirmPin + text
            }
            
            self.updateLabelValue(index: numberOfDigitsEntered-1, value: text)
            
        } else {
            
        }
    }
    
    //MARK: - AlertView method
    
    func showPinAlert(title: String, message: String) {
        let alert = UIAlertController(title:title  as String, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            self.isFirstPin = true
            self.initializePinView()
            self.enteredPin = ""
            self.numberOfDigitsEntered = 0
        }))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { action in
            
            self.isFirstPin = false
//            self.navigationItem.setHidesBackButton(false, animated:true);
            self.navigationItem.leftBarButtonItem = self.customBackBtnItem
            self.initializePinView()
            self.numberOfDigitsEntered = 0
            self.instructionLabel.text = "Confirm New PIN"
            if self.isFromLogin {
                self.instructionLabel.text = "Confirm the Security PIN"
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Navigation Methods
    
    func navigateToDashboard() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let validatePinViewController = storyBoard.instantiateViewController(withIdentifier: "ValidatePinViewController") as! ValidatePinViewController
        self.navigationController?.pushViewController(validatePinViewController, animated: true)
        
        
    }

    fileprivate func loadMainView() {
        
        // create viewController code...
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        
        //            let nvc: UINavigationController = UINavigationController(rootViewController: mainViewController)
        
        
        leftViewController.mainViewController = navigationController
        
        
        let slider = SlideMenuController(mainViewController:navigationController, leftMenuViewController: leftViewController)
        
        slider.automaticallyAdjustsScrollViewInsets = true
        slider.delegate = mainViewController

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        appDelegate.window?.rootViewController = slider
        appDelegate.window?.makeKeyAndVisible()
        
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapButton1(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton2(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton3(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton4(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton5(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton6(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton7(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton8(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton9(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    @IBAction func onTapButton0(_ sender: UIButton) {
        self.onPressPin(text: (sender.titleLabel?.text)!)
    }
    
    
    @IBAction func onTapDeleteButton(_ sender: UIButton) {
        if numberOfDigitsEntered > 0 {
            numberOfDigitsEntered -= 1
            let passedLabel = labelsArray[numberOfDigitsEntered] as UILabel
            passedLabel.text = dashCharacter
            if isFirstPin == true {
                if enteredPin.count > 0 {
                    enteredPin.removeLast()
                }
            } else {
                if enteredConfirmPin.count > 0 {
                    enteredConfirmPin.removeLast()
                }
            }
        }
    }
    
    @IBAction func onTapCancelButton(_ sender: UIButton) {
        self.loadMainView()
    }
    
    @IBAction func onTapContinueButton(_ sender: UIButton) {
        self.loadMainView()
    }
}
