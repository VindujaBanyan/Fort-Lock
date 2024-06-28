//
//  CommonSuccessViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/6/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class CommonSuccessViewController: UIViewController {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    var isFromRFIDScreen = Bool()
    var isFromFingerPrintScreen = Bool()
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize methods
   
    func initialize() {
        if isFromRFIDScreen {
            updateOtherUI(titleString: "Add RFID", instructionString: RFID_ADDED_SUCCESS)
        }
        
        if isFromFingerPrintScreen {
            updateOtherUI(titleString: "Add Finger Print", instructionString: FP_ADDED_SUCCESS)
        }
//        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.setHidesBackButton(true, animated:true)
    }
    
    func updateOtherUI(titleString: String, instructionString: String) {
        title = titleString
        instructionLabel.text = instructionString
    }

   // MARK: - IBActions

    @IBAction func onTapContinueButton(_ sender: Any) {
        
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: LockDetailsViewController.self) {
                _ =  self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
}
