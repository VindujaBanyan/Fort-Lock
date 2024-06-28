//
//  LockHistoryViewController.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/19/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
enum LockHistoryType:String{
    case bluetooth = "B"
    case wifi = "W"
    case rfid = "R"
    case fp = "F"
    case pin = "P"
    case otp = "O"
    case iot = "I"

    func imageName() -> String{
        switch self {
        case .bluetooth:
            return "Bluetooth"
        case .wifi:
            return "Wifi"
        case .rfid:
            return "Rfid"
        case .fp:
            return "fp"
        case .pin:
            return "Pin"
        case .otp:
            return "Otp"
        case .iot:
            return "Cloud"
        }
    }
}
class LockHistoryModel{
    var date:String = ""
    var time:String = ""
    var lockHistoryType:LockHistoryType = .bluetooth
    var userName:String = ""
    var role = ""
    func mapJson(json:[String:Any]){
        self.date = json["date"] as! String
        self.time = json["time"]  as! String
        //                self.time = convertTimeFormater(self.time)
        //                let fullDate = "\(self.date) \(self.time)"
        //                self.date = convertDateFormater(fullDate)
        //        self.time = Utilities().getTimeFromUTC(time)
        //        //        let fullDate = "\(self.date) \(self.time)"
        //        self.date = convertDateFormater(self.date)
        
        
        if let type = json["type"]{
            self.lockHistoryType = LockHistoryType(rawValue:type as! String) ?? .bluetooth
        }
        
        if json["type"] as! String == "B" || json["type"] as! String == "W" || json["type"] as! String == "I" {
            let userDetail = json["userDetails"] as! [String:String]
            self.userName = userDetail["username"] ?? "User"
            self.role = json["role"] as! String
            
        } else if json["type"] as! String == "F" {
            
            if json["userDetails"] is NSNull {
                if json["registrationDetails"] is NSNull {
                } else {
                    let registrationDetail = json["registrationDetails"] as! [String:String]
                    self.userName = registrationDetail["name"] ?? "User"
                }
            } else {
                let userDetail = json["userDetails"] as! [String:String]
                self.userName = userDetail["username"] ?? "User"
            }
            if json["role"] is NSNull {
                self.role = ""
            } else {
                self.role = json["role"] as! String
            }
            
            /*"type" : "F",
            "userDetails" : {
                    "id" : "355",
                    "username" : "David Albert"
                  },
            for registered user
            "registrationDetails" : { "id" : "355",
                    "username" : "David Albert"
                  },
            for guest user
*/
        }else if json["type"] as! String == "O" || json["type"] as! String == "P"{
            if(json["type"] as! String == "O"){
                self.userName = "OTP"
            }
            else{
                if json["userDetails"] is NSNull {
                    if json["registrationDetails"] is NSNull {}
                    else{
                        let registrationDetail = json["registrationDetails"] as! [String:String]
                        self.userName = registrationDetail["name"] ?? "PIN"
                    }
                }
            }
            
            self.role = json["slot"] as! String
        } else {
            self.userName = "RFID"
            self.role = json["slot"] as! String
        }
    }
    
    func activityLog() -> String {
        return "\(userName) (\(role)) engaged the lock"
    }
    
    func activityTime() -> String {
        return "\(date) \(time)"
    }
    
    func convertDateFormater(_ date: String) -> String
    {
        let dateFormatter = DateFormatter()
        //        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: date)
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return  dateFormatter.string(from: date!)
    }
    
    func convertTimeFormater(_ time: String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = dateFormatter.date(from: time)
        dateFormatter.dateFormat = "hh:mm:ss a"
        return  dateFormatter.string(from: date!)
    }
}


class LockHistoryViewController: UIViewController {

    @IBOutlet var historyTableView:UITableView!
    @IBOutlet var historyButton: UIButton?
    @IBOutlet var natificationButton: UIButton?
    @IBOutlet var historyLabel: UILabel?
    @IBOutlet var notificationLabel: UILabel?

    var pagination:TablePagination = TablePagination()
    var lockId:String = ""
    var lockHistoryArray:[LockHistoryModel] = []
    var isHistoryTapped = Bool()
    var notificationPagination: TablePagination = TablePagination()
    var notificationListArray:[ActivityNotificationListModel] = []
    var isFromRefresh = Bool()
    var isAllDataFetched = Bool()
    var isAllNotificationDataFetched = Bool()
    let refresher = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Activity Logs"
//        historyTableView.backgroundColor = UIColor.white
        addBackBarButton()
        registerTableViewCell()
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        DispatchQueue.global(qos: .background).async {
            LockWifiManager.shared.localCache.checkAndUpdateLogs { (status) in
                self.getActivityList()
            }
        }

        updateHistoryListUI()
        isHistoryTapped = true

        pagination.offset = 0
        notificationPagination.offset = 0
        isFromRefresh = true
        isAllDataFetched = false
        isAllNotificationDataFetched = false
        self.addRefreshController()

//        getActivityList()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    // MARK: - Refresh controller
    
    func addRefreshController() {
        self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refresher.addTarget(self, action: #selector(refreshCall), for: .valueChanged)
        
        self.historyTableView!.addSubview(self.refresher)
    }
    
    @objc func refreshCall() {
        //print("refresh called")
        
        isFromRefresh = true
        if isHistoryTapped {
            pagination.offset = 0
            isAllDataFetched = false
            getActivityList()
        } else {
            notificationPagination.offset = 0
            isAllNotificationDataFetched = false
            getActivityNotificationList()
        }
    }

    // MARK: - Register Cell
    
    func registerTableViewCell() {
        let nib1 = UINib.init(nibName: "LockHistoryTableViewCell", bundle: nil)
        self.historyTableView.register(nib1, forCellReuseIdentifier: "LockHistoryTableViewCell")
        
        let nib2 = UINib.init(nibName: "NotificationTableViewCell", bundle: nil)
        self.historyTableView.register(nib2, forCellReuseIdentifier: "NotificationTableViewCell")
    }
    
    func reloadTableData() {
        self.historyTableView.reloadData()
    }
    
    //MARK: - Navigation BarButton
    
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
    
    @objc func popToViewController() {
        navigationController!.popViewController(animated: false)
    }

    // MARK: - UI update Methods
    
    func updateHistoryListUI() {
        notificationLabel?.backgroundColor = UIColor.clear
        historyLabel?.backgroundColor = TABS_BGCOLOR
        natificationButton?.setTitleColor(UIColor.white, for: .normal)
        historyButton?.setTitleColor(TABS_BGCOLOR, for: .normal)
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapHistoryButton(_ sender: UIButton) {
        isHistoryTapped = true
        updateHistoryListUI()
        pagination.offset = 0
        isAllDataFetched = false
        isFromRefresh = true
        getActivityList()
        historyTableView.reloadData()
    }
    
    @IBAction func onTapNotificationButton(_ sender: UIButton) {
        isHistoryTapped = false
        notificationPagination.offset = 0
        isAllNotificationDataFetched = false
        isFromRefresh = true
        historyLabel?.backgroundColor = UIColor.clear
        notificationLabel?.backgroundColor = TABS_BGCOLOR
        historyButton?.setTitleColor(UIColor.white, for: .normal)
        natificationButton?.setTitleColor(TABS_BGCOLOR, for: .normal)
        getActivityNotificationList()
        historyTableView.reloadData()
    }
    
    // MARK: - Service Methods
    
    func getActivityList(){
        if Connectivity().isConnectedToInternet() == false{
            Utilities.showErrorAlertView(message: INTERNET_CONNECTION_VALIDATION, presenter: self)
            return
        }
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

        pagination.limit = 50 //pagination limit 50
        let paginationString = pagination.paginationString()
        if pagination.shouldStopPaginate == true {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            pagination.shouldStopPaginate = false
            pagination.offset = 0

            return
        }

        let url = ServiceUrl.BASE_URL + "activities/activitylist?id=\(lockId)&\(paginationString)"
        self.getActivityListViewModel(url: url, userDetails: [:]) {[unowned self] (lockHistoryArray, error) in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()

            LockWifiManager.shared.localCache.updateOfflineItems()
            
            if self.isFromRefresh {
                self.isFromRefresh = false
                self.lockHistoryArray.removeAll()
                self.isAllDataFetched = false
            }
            
            if self.lockHistoryArray.count < self.pagination.limit {
                self.isAllDataFetched = true
            }
            if let _lockHistoryArray = lockHistoryArray{
                self.lockHistoryArray.append(contentsOf: _lockHistoryArray)
                DispatchQueue.main.async{[unowned self] in
                    self.reloadTableData()
                }
                if _lockHistoryArray.count < self.pagination.limit{
                    self.pagination.stopPaginate()
                }
            }
            LoaderView.sharedInstance.hideShadowView(selfObject: self)
        }
    }
    
    func getActivityNotificationList(){
        if Connectivity().isConnectedToInternet() == false{
            Utilities.showErrorAlertView(message: INTERNET_CONNECTION_VALIDATION, presenter: self)
            return
        }
        LoaderView.sharedInstance.showShadowView(title: "Loading", selfObject: self)
        let notificationPaginationString = notificationPagination.paginationString()
        if notificationPagination.shouldStopPaginate == true {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            notificationPagination.shouldStopPaginate = false
            notificationPagination.offset = 0

            return
        }
        let url = ServiceUrl.BASE_URL + "activities/masterlog?lock_id=\(lockId)&\(notificationPaginationString)"
        LoaderView.sharedInstance.showShadowView(title: "Loading", selfObject: self)
        self.getActivityNotificationListViewModel(url: url, userDetails: [:]) { [unowned self] (notificationListArray, error) in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            if self.isFromRefresh {
                self.isFromRefresh = false
                self.notificationListArray.removeAll()
                self.isAllNotificationDataFetched = false
            }
            
            if self.notificationListArray.count < self.notificationPagination.limit {
                self.isAllNotificationDataFetched = true
            }
            
            if let _notificationListArray = notificationListArray{
                self.notificationListArray.append(contentsOf: _notificationListArray)
                DispatchQueue.main.async{[unowned self] in
                    self.reloadTableData()
                }
                if _notificationListArray.count < self.notificationPagination.limit{
                    self.notificationPagination.stopPaginate()
                }
            }
            LoaderView.sharedInstance.hideShadowView(selfObject: self)
        }
    }
}

// MARK: - UITableView Delegate and Data source

extension LockHistoryViewController:UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isHistoryTapped {
            return lockHistoryArray.count
        } else {
            return notificationListArray.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isHistoryTapped {
            let cell = historyTableView.dequeueReusableCell(withIdentifier: "LockHistoryTableViewCell") as! LockHistoryTableViewCell
            cell.selectionStyle = .none
            let lockHistory = lockHistoryArray[indexPath.row]
            cell.iconView.image = UIImage(named:lockHistory.lockHistoryType.imageName())
            cell.activityLabel.text = lockHistory.activityLog()
//            cell.dateTimeLabel.text = lockHistory.activityTime()
            cell.dateTimeLabel.text =  Utilities().UTCToLocal(date: lockHistory.activityTime())
            return cell
        } else {
            
            let cell = historyTableView.dequeueReusableCell(withIdentifier: "NotificationTableViewCell") as? NotificationTableViewCell
            cell?.selectionStyle = .none
            
            let notificationObj = notificationListArray[indexPath.row]
            
            cell?.notificationDetailLabel.text = notificationObj.log_msg // "Notification msg"
//            cell?.notificationDateTimeLabel.text = Utilities().convertDateAndTimeFormatter(notificationObj.log_datetime)  //"created date & time"
            cell?.notificationDateTimeLabel.text = Utilities().UTCToLocal(date: notificationObj.log_datetime)   //"created date & time"
            return cell!
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //        if indexPath.row == (lockHistoryArray.count - 1){
        //            pagination.paginate()
        //            getActivityList()
        //        }
        
        if isHistoryTapped {
            if self.lockHistoryArray.count - 1 == indexPath.row {
                if !isAllDataFetched && !isFromRefresh {
                    pagination.paginate()
                    getActivityList()
                }
            }
        } else {
            if self.notificationListArray.count - 1 == indexPath.row {
                if !isAllNotificationDataFetched && !isFromRefresh {
                    notificationPagination.paginate()
                    getActivityNotificationList()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        /*
        if isHistoryTapped {
            pagination.paginate()
            getActivityList()
        } else {
            notificationPagination.paginate()
            getActivityNotificationList()
        }*/
    }
}


extension LockHistoryViewController {
    func getActivityListViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [LockHistoryModel]?, _ error: NSError?) -> Void) {

        DataStoreManager().getActivityListServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
            if result != nil {
                print("result getactivitylist ==> \(String(describing: result))")
                var lockHistoryArray = [LockHistoryModel]()

                if result!["data"].count > 0 {
                    for i in 0..<result!["data"].count {
                        let dict = result!["data"][i].dictionaryObject
                        let lockHistory = LockHistoryModel()
                        if dict!["type"] as! String == "B" || dict!["type"] as! String == "W" || dict!["type"] as! String == "I" {
                            //print("User details ==> ")
                            //print(dict!["userDetails"])
                            if !(dict!["userDetails"] is NSNull) {
                                lockHistory.mapJson(json: dict!)
                                lockHistoryArray.append(lockHistory)
                            }
                        } else if dict!["type"] as! String == "R" || dict!["type"] as! String == "F" || dict!["type"] as! String == "O" || dict!["type"] as! String == "P" {
                            // RFID - slot number
                            lockHistory.mapJson(json: dict!)
                            lockHistoryArray.append(lockHistory)

                        }
//                        else if dict!["type"] as! String == "F" {
//                            // RFID - slot number
//                            lockHistory.mapJson(json: dict!)
//                            lockHistoryArray.append(lockHistory)
//
//                        }
                        
                    }
                }
                callback(lockHistoryArray, error)
            } else {
                callback(nil, error)

            }

        })
    }
    
    func getActivityNotificationListViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [ActivityNotificationListModel]?, _ error: NSError?) -> Void) {
        
        DataStoreManager().getActivityNotificationListServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject]) { (result, error) in
            
            if result != nil {
                //print("result getactivitylist ==> \(String(describing: result))")
                var notificationArray = [ActivityNotificationListModel]()
                if result!["data"].count > 0 {
                    for i in 0..<result!["data"].count {
                        
                        let notificationObj = ActivityNotificationListModel()
                        
                        notificationObj.log_msg = result!["data"][i]["log_msg"].rawValue as? String
                        notificationObj.key_id = result!["data"][i]["key_id"].rawValue as? String
                        notificationObj.lock_id = result!["data"][i]["lock_id"].rawValue as? String
                        notificationObj.activity_type = result!["data"][i]["activity_type"].rawValue as? String
                        notificationObj.parent_user_id = result!["data"][i]["parent_user_id"].rawValue as? String
                        notificationObj.user_id = (result!["data"][i]["user_id"].rawValue as? String)
                        notificationObj.id = result!["data"][i]["id"].rawValue as? String
                        notificationObj.log_datetime = result!["data"][i]["log_datetime"].rawValue as? String
                        notificationObj.request_id = result!["data"][i]["request_id"].rawValue as? String
                        
                        notificationArray.append(notificationObj)
                    }
                }
                callback(notificationArray, error)
            } else {
                callback(nil, error)
            }
        }
    }

}
