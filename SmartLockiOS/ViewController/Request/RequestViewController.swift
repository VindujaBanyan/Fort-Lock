//
//  RequestViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class RequestViewController: UIViewController, IndicatorInfoProvider {
    var itemInfo = IndicatorInfo(title: "Request", image: UIImage(named: "tab_users"))
    
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var noRequestView: UIView!
    @IBOutlet var requestTableView: UITableView!
    
    var requestListArray = [RequestListModel]()
    var requestPagination: TablePagination = TablePagination()
    let refresher = UIRefreshControl()
    
    var pageNumber: Int = 1
    var selectedIndex = Int()
    var selectedSection = Int()
    var isFromRefresh = Bool()
    var isAllDataFetched = Bool()
    
    private let notificationCenter = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
//        requestTableView.backgroundColor = UIColor.white
        
        notificationCenter
                          .addObserver(self,
                           selector:#selector(processBackgroundNotifiData(_:)),
                                       name: NSNotification.Name(BundleIdentifier),
                           object: nil)
    }
    
    @objc func processBackgroundNotifiData(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            let title = userInfo["title"] as? String
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && command == LockNotificationCommand.OWNER_TRANSFER.rawValue){
                let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.refreshCall()
                }))
                self.present(alert, animated: true, completion: nil)
            }else if (status == "failure" && command == LockNotificationCommand.OWNER_TRANSFER.rawValue){
                Utilities.showErrorAlertView(message: body ?? "", presenter: self)
            }
        }
    }
    //MARK : - Remove Notification
    deinit {
           notificationCenter
                        .removeObserver(self,
                        name: NSNotification.Name(BundleIdentifier) ,
                        object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("view will appear")
        requestPagination.offset = 0
        isFromRefresh = true
        isAllDataFetched = false

        self.getRequestList()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        requestPagination.offset = 0

        self.registerTableViewCell()
        self.addRefreshController()
        self.requestTableView.reloadData()
        self.noRequestView.isHidden = true
    }
    
    // MARK: - Refresh controller
    
    func addRefreshController() {
        self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refresher.addTarget(self, action: #selector(refreshCall), for: .valueChanged)

        self.requestTableView!.addSubview(self.refresher)
    }
    
    @objc func refreshCall() {
        //print("refresh called")
        
        requestPagination.offset = 0
        isFromRefresh = true
        isAllDataFetched = false
        self.getRequestList()
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        let nib1 = UINib(nibName: "RequestUserTableViewCell", bundle: nil)
        self.requestTableView.register(nib1, forCellReuseIdentifier: "RequestUserTableViewCell")
        
        let nib2 = UINib(nibName: "UpdatedRequestTableViewCell", bundle: nil)
        self.requestTableView.register(nib2, forCellReuseIdentifier: "UpdatedRequestTableViewCell")
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return self.itemInfo
    }
    
    // MARK: - Service Call
    
    @objc func getRequestList() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let requestPaginationString = requestPagination.paginationString()
        if requestPagination.shouldStopPaginate == true {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            requestPagination.shouldStopPaginate = false
            requestPagination.offset = 0
            return
        }

        let urlString = ServiceUrl.BASE_URL + "requests/requestlist?\(requestPaginationString)"
        
        RequestViewModel().getRequestListServiceViewModel(url: urlString, userDetails: [:]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            if result != nil {
                // implement pagenation
                
//                DispatchQueue.global(qos: .background).async {
//                    self.requestListArray.removeAll()
//                }
                
                /*
                self.requestListArray = result as! [RequestListModel]
                
                if self.requestListArray.count > 0 {
                    self.noRequestView.isHidden = true
                    self.requestTableView.isHidden = false
                    self.requestTableView.reloadData()
                    
                } else {
                    self.noRequestView.isHidden = false
                    self.instructionLabel.text = "You do not have any new request."
                    self.requestTableView.isHidden = true
                }
 */
                if self.isFromRefresh {
                    self.isFromRefresh = false
                    self.requestListArray.removeAll()
                    //print("isFromRefresh =============== >>>>>>>> \(self.requestListArray.count)")
                    self.isAllDataFetched = false
                }
                
                if result!.count < self.requestPagination.limit {
                    self.isAllDataFetched = true
                }
                
                
                if let _requestListArray = result as? [RequestListModel] {
                    //print("self.requestListArray count ==> \(self.requestListArray.count)")
                    self.requestListArray.append(contentsOf: _requestListArray)
                    DispatchQueue.main.async{[weak self] in
                        guard let self = self else { return }
                        self.requestTableView.reloadData()
                    }
                    if _requestListArray.count < self.requestPagination.limit{
                        self.requestPagination.stopPaginate()
                    }
                }
                
                self.requestTableView.isHidden = false
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                
                if message == INTERNET_CONNECTION_VALIDATION {
                    self.noRequestView.isHidden = false
                    self.instructionLabel.text = INTERNET_CONNECTION_VALIDATION
                    self.requestTableView.isHidden = true
                }
                self.view.makeToast(message)
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // User and Master Request
    
    func updateRequestServiceCall(_ requestId: String, _ requestStatus: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "requests/updaterequest?id=\(requestId)"
        
        let userDetailsDict = [
            "status": requestStatus,
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
        
        AssignUsersViewModel().updateRequestUserServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                //print("update request !!!!!!!!!!!")
                self.requestPagination.shouldStopPaginate = false
                self.requestPagination.offset = 0
                self.isFromRefresh = true
                self.getRequestList()
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
    
    // Transfer owner request update
    
    func updateTransferOwnerRequestServiceCall(_ keyId: String, _ requestStatus: String, requestId: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/transfer?id=\(keyId)"
        
        let userDetailsDict = [
            "request_id": requestId,
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
        
        TransferOwnerViewModel().updateTransferOwnerRequestUserServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                //print("update transfer owner @@@@@@@@@")
                self.requestPagination.shouldStopPaginate = false
                self.requestPagination.offset = 0
                self.isFromRefresh = true
                self.getRequestList()
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

// MARK: - RequestUsersProtocol

extension RequestViewController: RequestUsersProtocol {
    func updateRequestStatus(_ sender: UIButton, _ requestStatus: String) {
        self.selectedIndex = sender.tag % 1000
        self.selectedSection = sender.tag / 1000
        
        let requestObj = requestListArray[selectedIndex]
        
        
        
        if requestObj.keyDetails.userType!.lowercased() == UserRoles.owner.rawValue ||  requestObj.keyDetails.userType!.lowercased() == UserRoles.ownerid.rawValue {
            if requestStatus == "1" { // transfer owner accept
                if requestObj.lockDetails.lockVersion == lockVersions.version4_0.rawValue {
                    transferOwnerAcceptAlertMqtt(requestID: requestObj.requestId, serialNumber: requestObj.lockDetails.serialNumber)
                }else {
                    transferOwnerAcceptAlert(keyDetailsID: requestObj.keyDetails.id!, requestStatus: requestStatus, requestID: requestObj.requestId)
                }
            } else { // Transfer owner reject
                self.updateRequestServiceCall(requestObj.requestId, requestStatus)
            }
        } else { // Master and user request accept/reject
            self.updateRequestServiceCall(requestObj.requestId, requestStatus)
        }
    }
    
    func transferOwnerAcceptAlert(keyDetailsID: String, requestStatus: String, requestID: String) {
        
        let alert = UIAlertController(title: ALERT_TITLE, message: "Please ensure you are near the lock before accepting the request. Please engage with the lock immediately after accepting the request for security reasons.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { _ in
        }))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
            self.updateTransferOwnerRequestServiceCall(keyDetailsID, requestStatus, requestId: requestID)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func transferOwnerAcceptAlertMqtt(requestID: String, serialNumber: String) {
        
        let alert = UIAlertController(title: ALERT_TITLE, message: "Please engage with the lock immediately after accepting the request.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { _ in
        }))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
            self.acceptTranferOwnerViaMqtt(serialNumber: serialNumber, requestId: requestID)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func acceptTranferOwnerViaMqtt(serialNumber: String, requestId: String){
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        let urlString = ServiceUrl.BASE_URL + "locks/\(serialNumber)/transferowner/\(requestId)"
        RequestViewModel().acceptTranserOwnerViaMqttServiceViewModel(url: urlString, userDetails: [:]) { result, error in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                print("Success.....\(result ?? "")")
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - UITableview

extension RequestViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let requestListObj = self.requestListArray[indexPath.row] as RequestListModel
        
        if requestListObj.status == "0" {
            let cell = requestTableView.dequeueReusableCell(withIdentifier: "RequestUserTableViewCell") as? RequestUserTableViewCell
            cell?.selectionStyle = .none
          //  cell?.requesterNameLabel.text = requestListObj.requestFromUserDetails.username
            
            var userType = requestListObj.keyDetails.userType!
            
            if userType.lowercased() == UserRoles.owner.rawValue || userType.lowercased() == UserRoles.ownerid.rawValue {
                userType = "Owner"
            }
            
            let str1 = "You have received a request from \(requestListObj.requestFromUserDetails.username!) for"
            let str2 = requestListObj.lockDetails.name!
            let str3 = "to be a \(userType)"
            
            cell?.requestAcceptButton.tag = ((indexPath.section + 1) * 1000) + indexPath.row
            cell?.requestRejectButton.tag = ((indexPath.section + 1) * 1000) + indexPath.row
            
            cell?.requestDescriptionLabel.attributedText = Utilities().labelColorFormatter(firstStr: str1, secondStr: str2, thridStr: str3)
            
            cell?.requestUsersDelegate = self as RequestUsersProtocol
            return cell!
            
        } else {
            let cell = requestTableView.dequeueReusableCell(withIdentifier: "UpdatedRequestTableViewCell") as? UpdatedRequestTableViewCell
            cell?.selectionStyle = .none
           // cell?.requestedUserNameLabel.text = requestListObj.requestFromUserDetails.username
            cell?.requestStatusLabel.text = requestListObj.status
            if requestListObj.status == "1" {
                cell?.requestStatusLabel.text = "Accepted"
                cell?.requestStatusLabel.textColor = ACCEPT_COLOR
            } else if requestListObj.status == "2" {
                cell?.requestStatusLabel.text = "Rejected"
                cell?.requestStatusLabel.textColor = REJECT_COLOR
            } else {
                cell?.requestStatusLabel.text = "Withdrawn"
                cell?.requestStatusLabel.textColor = WITHDRAW_COLOR
            }
            cell?.requestStatusLabel.backgroundColor = UIColor.clear

            var userType = requestListObj.keyDetails.userType!
            
            if userType.lowercased() == UserRoles.owner.rawValue || userType.lowercased() == UserRoles.ownerid.rawValue {
                userType = "Owner"
            }
            
            let str1 = "You have received a request from \(requestListObj.requestFromUserDetails.username!) for"
            let str2 = requestListObj.lockDetails.name!
            let str3 = "to be a \(userType)"
            
            cell?.requestdescriptionLabel.attributedText = Utilities().labelColorFormatter(firstStr: str1, secondStr: str2, thridStr: str3)
            
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.requestListArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        /*
        //print("willDisplayFooterView #############")
        requestPagination.paginate()
        getRequestList()
 */
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.requestListArray.count - 1 == indexPath.row {
            if !isAllDataFetched && !isFromRefresh {
                requestPagination.paginate()
                getRequestList()
            } else {
                
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
