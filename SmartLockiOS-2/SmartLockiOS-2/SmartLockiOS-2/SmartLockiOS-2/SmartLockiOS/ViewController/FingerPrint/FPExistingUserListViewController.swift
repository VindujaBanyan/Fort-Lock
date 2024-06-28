//
//  FPExistingUserListViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/8/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit

class FPExistingUserListViewController: UIViewController {

    @IBOutlet weak var usersTableView: UITableView!
    
    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

    var lockId = String()
    var fpListArray = [FPModel]()
    var scratchCode = String()
    var lockConnection:LockConnection = LockConnection()
    var lockListDetailsObj = LockListModel(json: [:])
    var userListArray = [AssignUserDetailsModel]() {
        didSet {
            self.usersTableView.reloadData()
        }
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
        getExistingUserList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize method
    func initialize() {
        title = "Finger Print"
        addBackBarButton()
        usersTableView.tableFooterView = UIView()
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
    
    /// Pop to UIViewController
    @objc func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }

}

// MARK: - UITableview

extension FPExistingUserListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "cell")
        }
        
        let userObj = userListArray[indexPath.row]

        cell!.textLabel?.text = userObj.username
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userListArray.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let userID = userListArray[indexPath.row].id
        let filterArray = self.fpListArray.filter({ (fpModelObj) -> Bool in
            return fpModelObj.userId == userID
        })
        
        let customAddViewController = storyBoard.instantiateViewController(withIdentifier: "CustomAddViewController") as! CustomAddViewController
        customAddViewController.isFromRFIDScreen = false
        customAddViewController.isFromFingerPrintScreen = true
        customAddViewController.userID = userID ?? ""
        customAddViewController.lockConnection.selectedLock =  lockConnection.selectedLock
        customAddViewController.lockConnection.serialNumber = lockConnection.serialNumber
        customAddViewController.scratchCode = scratchCode
        customAddViewController.lockId = self.lockId
        customAddViewController.lockListDetailsObj = self.lockListDetailsObj
        if filterArray.count == 0 {
            customAddViewController.isAlreadyFingerPrintAssigned = false
            customAddViewController.guestUserName = userListArray[indexPath.row].username
        } else {
            let fpModelObj = filterArray[0]
            customAddViewController.assignedkeys = fpModelObj.key
            customAddViewController.isAlreadyFingerPrintAssigned = true
            customAddViewController.fingerPrintID = fpModelObj.id
            customAddViewController.guestUserName = fpModelObj.userDetails.username
        }
        self.navigationController?.pushViewController(customAddViewController, animated: true)
    }
}


// MARK: - Service call
extension FPExistingUserListViewController {
        
    // Get RFID list
    @objc func getExistingUserList() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/userlist?lock_id=\(self.lockId)"
        
        FPViewModel().getExistingLockUserServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
           
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if result != nil {
                self.userListArray = result!
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showCustomAlert(with: message)
            }
        }
    }
    
    /// Add fingerprint with
    /// - Parameter isExistingUser: Already fingerprint added user - status
    func addFingerPrint(isExistingUser: Bool) {
        
        let urlString = ServiceUrl.BASE_URL + "addfingerprint"
            
            
            var userDetailsDict = [
                "lock_id": "",
                "key": "",
                "name": "0",
                ]

        if isExistingUser {
            userDetailsDict["user_id"] = ""
        }
        
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
        
//        {"lock_id":"449","name":"David Albert","key":"[6]","user_id":"355"}

//            ["04"]
                
        FPViewModel().getFPListServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
           
            if result != nil {
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showCustomAlert(with: message)
            }
        }
    }
    
    // Show custom alert with string
    func showCustomAlert(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
