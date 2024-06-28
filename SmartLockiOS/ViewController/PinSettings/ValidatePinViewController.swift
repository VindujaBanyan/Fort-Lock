//
//  ValidatePinViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 01/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class ValidatePinViewController: UIViewController {
    @IBOutlet var pinView: UIView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    @IBOutlet var button3: UIButton!
    @IBOutlet var button4: UIButton!
    @IBOutlet var button5: UIButton!
    @IBOutlet var button6: UIButton!
    @IBOutlet var button7: UIButton!
    @IBOutlet var button8: UIButton!
    @IBOutlet var button9: UIButton!
    @IBOutlet var button0: UIButton!
    
    @IBOutlet var deleteButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate: LeftMenuProtocol?
    
    var isFromAppdelegate = Bool()

    var isFromResetPIN = Bool()
    let numberOfPinDigits = 4
    var numberOfDigitsEntered = 0
    
    let bulletCharacter: String = "\u{25CF}"
    let dashCharacter: String = "\u{2010}"
    
    ////////////////////////
    var labelsArray: [UILabel] = []
    //    var pinTextField = UITextField()
    var enteredPin: String = ""
    var isFromSettings = Bool()
    var isFromValidation = Bool()
    var launchType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.endEditing(true)
        self.initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.removeNavigationBarItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Initialize methods
    
    func initialize() {
        self.title = "Security PIN"
        self.updateTextFont()
        self.createPinView()
        self.updateButtonProperties()
        self.instructionLabel.text = "Enter the current PIN"
        if isFromAppdelegate {
            self.instructionLabel.text = "Enter the Security PIN"
            self.cancelButton.isHidden = true
        }
    }
    
    func updateTextFont() {
        
        self.instructionLabel.font = UIFont.setRobotoRegular17FontForTitle
        
        self.cancelButton.titleLabel?.font = UIFont.setRobotoRegular20FontForTitle
        self.deleteButton.titleLabel?.font = UIFont.setRobotoRegular20FontForTitle

    }
    
    // MARK: - Navigation Bar button
    
    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToRoot), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    @objc func popToRoot() {
        self.navigationController!.popViewController(animated: false)
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
    
    // MARK: - Button Properties
    
    func setButtonProperties(button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = button.frame.size.width / 2.0
        button.layer.masksToBounds = true
    }
    
    func updateButtonProperties() {
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
    
    // MARK: - PIN View Creation
    
    func createPinView() {
        // Pin label creation
        var xPos = 0
        let labelWidthHeight = 50
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        
        for _ in 0...self.numberOfPinDigits - 1 {
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
        //        pinTextField.text = ""
        for i in 0...self.labelsArray.count - 1 {
            let passedLabel = labelsArray[i] as UILabel
            passedLabel.text = dashCharacter
        }
    }
    
    func updateLabelValue(index: Int, value: String) {
        var valueStr = ""
        var indexv = index
        
        if value == "" {
            indexv = index - 1
            valueStr = self.dashCharacter
        } else {
            valueStr = self.bulletCharacter
        }
        
        if indexv < self.labelsArray.count {
            let passedLabel = labelsArray[indexv] as UILabel
            passedLabel.text = valueStr
        }
    }
    
    // MARK: - Validation Methods
    
    func onPressPin(text: String) {
        self.numberOfDigitsEntered += 1
        
        //print("=========================")
        //print("numberOfDigitsEntered ==> \(self.numberOfDigitsEntered)")
        //print("numberOfPinDigits ==> \(self.numberOfPinDigits)")
        
        if self.numberOfDigitsEntered == self.numberOfPinDigits {
            self.updateLabelValue(index: self.numberOfDigitsEntered - 1, value: text)
            
            //print("done")

            //                verify pin
            self.enteredPin = self.enteredPin + text
            //print("enteredPin ==> \(self.enteredPin)")

            let keychain = KeychainSwift()
//            let a = keychain.get("securityPIN")
//            //print("securityPIN ==> \(String(describing: a!))")
            
            let password = "RNCryptorpassword"
            let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
            do {
                let decryptData = try RNCryptor.decrypt(data: decryptValue!, withPassword: password)
                let decryptedPINString = String(decoding: decryptData, as: UTF8.self)
                //print("securityPIN ==> \(String(describing: decryptedPINString))")
                
                if self.enteredPin == decryptedPINString {
                    //                self.dismissPinValidationScreen()
                    if self.isFromResetPIN {
                        // navigate to create PIN
                        
                    } else {
                        // dismiss validate pin VC --> app launch pin validation success
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
                        guard let self = self else { return }
                        // your code here
                        self.view.endEditing(true)
                        if self.isFromAppdelegate {

                            self.loadMainView()
                        } else {
                            self.navigateToCreatePinVC()
                        }
                    }

                    //                self.navigationController?.popViewController(animated: true)
                } else {
                    let alert = UIAlertController(title:"Incorrect Pin", message: "", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.enteredPin = ""
                        self.numberOfDigitsEntered = 0
                        self.initializePinView()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                }
            } catch {
                //print(error)
            }
            
            
            
        } else if self.numberOfDigitsEntered < self.numberOfPinDigits {
            self.enteredPin = self.enteredPin + text
            self.updateLabelValue(index: self.numberOfDigitsEntered - 1, value: text)
            
        } else {
        }
    }
    
    // MARK: - Navigation Methods
    
    func dismissPinValidationScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func navigateToCreatePinVC() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let pinViewController = storyBoard.instantiateViewController(withIdentifier: "PinViewController") as! PinViewController
        pinViewController.isFromResetPIN = true
        self.navigationController?.pushViewController(pinViewController, animated: true)
    }
    
    // MARK: - AlertView Method
    
    func showPinAlert(title: String, message: String) {
        let alert = UIAlertController(title: title as String, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_: UIAlertAction!) in
            self.initializePinView()
            self.enteredPin = ""
            self.numberOfDigitsEntered = 0
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.initializePinView()
            self.numberOfDigitsEntered = 0
            
        }))
        self.present(alert, animated: true, completion: nil)
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
        if self.numberOfDigitsEntered > 0 {
            self.numberOfDigitsEntered -= 1
            let passedLabel = labelsArray[numberOfDigitsEntered] as UILabel
            passedLabel.text = dashCharacter
            if self.enteredPin.count > 0 {
                self.enteredPin.removeLast()
            }
        }
    }
    
    @IBAction func onTapCancelButton(_ sender: UIButton) {
        self.loadMainView()
    }
}
