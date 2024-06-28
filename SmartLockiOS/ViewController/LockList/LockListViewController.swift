//
//  LockListViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 11/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import JJFloatingActionButton
import UIKit
import XLPagerTabStrip
import NetworkExtension
import FirebaseRemoteConfig
import CoreLocation
import SwiftyJSON

class LockConnection {
    
    var selectedLock :BluetoothAdvertismentData?
    var ssid:String?
    var isConnectedByBLE:Bool = true
    var hardwareData:LockHardwareDetails?
    var serialNumber = ""
    var isLockFound:Bool{
        if selectedLock != nil {
            return true
        }
        else if ssid != nil {
            return true
        }
        return false
    }
    func isConnectedToLockWifi() -> Bool {
        //ssid check not working in iOS 14(Bug fix)
        
        print("isConnectedToLockWifi")
        var ssid = LockWifiManager.shared.getWiFiSsid()
        print("ssid ====>>>> \(String(describing: ssid))")
        if ssid?.lowercased().contains(JsonUtils().getManufacturerCode().lowercased()) == true{
            ssid = ssid?.replacingOccurrences(of: JsonUtils().getManufacturerCode(), with: "")
            self.ssid = ssid
            return true
        }
        return false
    }
    func isConnectedToLockWifi(ssidName:String) -> Bool {
        print("isConnectedToLockWifi with name\(ssidName)")
        
        //ssid check not working in iOS 14(Bug fix)
        let ssid = LockWifiManager.shared.getWiFiSsid()
        if ssid?.lowercased().contains(ssidName.lowercased()) == true{
            self.ssid = ssid
            return true
        }
        return false
    }
}
class LockListViewController: UIViewController, CLLocationManagerDelegate, IndicatorInfoProvider {
    
    
    @IBOutlet var lockListTableView: UITableView!
    
    @IBOutlet var addLockView: UIView!
    @IBOutlet var noLocksLabelView: UIView!
    
    @IBOutlet var lockNameTextField: TweeAttributedTextField!
    @IBOutlet var lockCodeTextField: TweeAttributedTextField!
    @IBOutlet weak var lockDeviceTextField: TweeAttributedTextField!
    
    @IBOutlet var addLockButton: UIButton!
    @IBOutlet var cancelLockButton: UIButton!
    var lockConnection:LockConnection = LockConnection()
    fileprivate let actionButton = JJFloatingActionButton()
    var lockListArray = [LockListModel]()
    var lockListDetailsObj = LockListModel(json: [:])
    let refresher = UIRefreshControl()
    
    var ownerIDArray = [String]() // save owner IDs from HARDWARE
    var keyArray = [String]() // save keys from HARDWARE
    var availableListOfLock:[BluetoothAdvertismentData] = []
    let lockIDSlotArray = NSMutableArray()
    let lockKeysSlotArray = NSMutableArray()
    
    var availableListOfLockCount = Int()
    var recentlyProcessedLockIndex = Int()
    
    var scannedBLEDevicesListArray: [BluetoothAdvertismentData] = []
    var triedBLEDeviceList: [String] = []
    var strServerTime = ""
    var isConnectedToBLE = Bool()
    var isConnectedViaWIFI = Bool()
    var isWIFIChecked = Bool()
    var isAddLockScanning = Bool()
    var isActivationFailed = Bool()
    var isPassageModeEnabled = Bool()
    
    var remoteConfig: RemoteConfig!
    var updatePriority : Priority!
    var message = ""
    
    var isReadAllKeys = Bool()
    var isAddButtonTapped = Bool()
    
    var isAddLockServiceFailed = Bool()
    
    var allDataFetched = false
    var limit          = 50
    var offset         = 0
    
    var notificationPagination: TablePagination = TablePagination()
    
    var locationManager: CLLocationManager?
    
    var itemInfo = IndicatorInfo(title: "Locks", image: UIImage(named: "tab_lock"))
    
    init(itemInfo: IndicatorInfo) {
        self.itemInfo = IndicatorInfo(title: "Locks", image: UIImage(named: "menu"))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        lockListTableView.backgroundColor = UIColor.white
        NotificationCenter.default.addObserver(self, selector: #selector(handlePassageModeChange(_:)), name: Notification.Name("PassageModeDidChangeNotification"), object: nil)
        self.initialize()
        
        //    if IsFromProduction {
        //        self.checkForceUpdate()
        //    }
        //        self.getServerTimeAPICall()
        
       // self.checkForBLEAccess()
        self.lockDeviceTextField.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("GetUpdatedLockList"), object: nil)
        
        BLELockAccessManager.shared.delegate = self
        BLELockAccessManager.shared.initialize()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NSNotification.Name(rawValue: "connectedToWIFI"), object: nil)
        
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "isLockListScreen")
        defaults.synchronize()
        
        updateUIWithFloatingButton()
        setButtonProperties()
        self.getAppConfiguration()
        //        if self.presentedViewController == nil {
        
        if Connectivity().isConnectedToInternet() {
            self.updateLocallyAddedLocks()
            //                self.updateEditedLockList()
            //                DispatchQueue.main.async {
            //                    self.getServerTimeAPICall()
            //                }
            self.getLockListServiceCall()
            LockWifiManager.shared.localCache.updateOfflineItems()
        }
        else{
            self.getListDataFromLocal()
            
        }
        self.checkForBLEAccessWithoutAlert()
        //        }
        
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        print("Notification called")
        self.getLockListServiceCall()
    }
    
    func getServerTimeAPICall()
    {
        self.getServerTimeInBlock(withSuccessionBlock: { (response) in
            self.strServerTime = response
            self.lockListTableView.reloadData()
        }) { (error) in
            print(error)
        }
    }
    
    func getServerTimeInBlock(withSuccessionBlock successBlock: @escaping (String) -> Void, andFailureBlock failureBlock: @escaping (String) -> Void)
    {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "users/getcurrenttime"
        NetworkManager().getServerDateAndTimeServiceCall(url: urlString, userDetails: [:]) { (response, error) in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            
            if response != nil
            {
                if let data = response!["data"].dictionary
                {
                    self.strServerTime = data["server_time"]?.rawString() ?? ""
                    successBlock(data["server_time"]?.rawString() ?? "")
                }
            }
            else
            {
                failureBlock("")
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
                //                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                //
                //                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                //                }))
                //                self.present(alert, animated: true, completion: nil)
            }
            
        }
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        // Do something now
        //print("connected to wifi ============ !!!!!!!!!!!!!")
        if self.lockConnection.isConnectedToLockWifi() == true {
            if self.isAddButtonTapped == true {
                self.addLockViaConnectedWIFI()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //BLELockAccessManager.shared.stopPeripheralScan()
        
        triedBLEDeviceList = []
        lockNameTextField.text = ""
        lockCodeTextField.text = ""
        lockNameTextField.hideInfo()
        lockCodeTextField.hideInfo()
        lockNameTextField.textColor = UIColor.black
        lockCodeTextField.textColor = UIColor.black
        
        lockNameTextField.resignFirstResponder()
        lockCodeTextField.resignFirstResponder()
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear ========")
        NotificationCenter.default.removeObserver(self, name: Notification.Name("GetUpdatedLockList"), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func checkForBLEAccess(){
        let access = BLELockAccessManager.shared.checkForBluetoothAccess()
        if access.canAccess == true{
            
            //print("checkForBLEAccess ==> ")
            //            self.initializeScan()
        }
        else {
            let alert = UIAlertController(title:ALERT_TITLE, message: access.errorMessage, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkForBLEAccessWithoutAlert(){
        let access = BLELockAccessManager.shared.checkForBluetoothAccess()
        if access.canAccess == true{
            //            self.initializeScan()
        }
    }
    func getListDataFromLocal() {
        let localDB = CoreDataController()
        //        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
        if let savedListObj = localDB.fetchLockList() as? [LockListModel] {
            
            self.lockListArray = savedListObj
            
            
            var tempLockListArray = [LockListModel]()
            
            for lockObj in self.lockListArray {
                
                var userObj = UserLockRoleDetails(json: [:])
                if lockObj.lock_keys.count > 0 {
                    userObj = lockObj.lock_keys[1] as UserLockRoleDetails
                    
                    if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                        
                        let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
                        let startDateString = Utilities().toDateString(date: startDate)
                        
                        let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
                        let endDateString = Utilities().toDateString(date: endDate)
                        
                        let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                        let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                        
                        let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                        let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        let currentDate = NSDate()
                        let currentDateString = dateFormatter.string(from: currentDate as Date)
                        
                        let currentDateNew = Utilities().toDate(dateString: currentDateString)
                        let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                        
                        let dateFormatter1 = DateFormatter()
                        dateFormatter1.dateFormat = "HH:mm"
                        let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                        
                        //print("startDate ========> \(startDate)")
                        //print("startDateString ========> \(startDateString)")
                        
                        //print("endDate ========> \(endDate)")
                        //print("endDateString ========> \(endDateString)")
                        
                        //print("startTime ========> \(startTime)")
                        //print("startTimeString ========> \(startTimeString)")
                        
                        //print("endTime ========> \(endTime)")
                        //print("endTimeString ========> \(endTimeString)")
                        
                        //print("currentDateNew ========> \(currentDateNew)")
                        //print("currentDateStringNew ========> \(currentDateStringNew)")
                        
                        
                        if startDateString <= currentDateStringNew && currentDateStringNew <= endDateString {
                            tempLockListArray.append(lockObj)
                        }
                        
                        /*
                         if startDate <= currentDateNew && currentDateNew <= endDate {
                         tempLockListArray.append(lockObj)
                         }
                         */
                        /*
                         if currentDateNew == endDate {
                         if currentTimeString > endTimeString {
                         // expired
                         } else {
                         tempLockListArray.append(lockObj)
                         }
                         } else if currentDateNew > endDate {
                         // expired
                         } else  if startDate > currentDateNew {
                         
                         }
                         /*else if startDate < currentDateNew && currentDateNew < endDate {
                          
                          if currentTimeString > endTimeString {
                          // expired
                          } else {
                          tempLockListArray.append(lockObj)
                          }
                          }*/
                         else {
                         
                         tempLockListArray.append(lockObj)
                         }
                         */
                    } else {
                        tempLockListArray.append(lockObj)
                    }
                }
            }
            self.lockListArray = tempLockListArray
            if self.lockListArray.count > 0 {
                self.lockListTableView.isHidden = false
                self.addLockView.isHidden = true
                self.noLocksLabelView.isHidden = true
            } else {
                self.lockListTableView.isHidden = true
                self.addLockView.isHidden = true
                self.noLocksLabelView.isHidden = false
            }
            self.lockListTableView.reloadData()
        }
        //}
    }
    
    // MARK: - Initialize methods
    
    func initialize() {
        self.registerTableViewCell()
        self.setButtonProperties()
        self.addFloatingButton()
        
        self.addRefreshController()
        
        self.lockCodeTextField.delegate = self
        self.lockNameTextField.delegate = self
        BLELockAccessManager.shared.delegate = self
        BLELockAccessManager.shared.initialize()
        
        self.registerLocation()
    }
    
    func registerLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    //MARK: - Add refresh controller
    
    func addRefreshController() {
        self.refresher.attributedTitle = NSAttributedString(string: "")
        self.refresher.addTarget(self, action: #selector(self.refreshCall), for: .valueChanged)
        self.lockListTableView!.addSubview(self.refresher)
    }
    
    @objc func refreshCall() {
        if Connectivity().isConnectedToInternet() {
            //            LockWifiManager.shared.localCache.updateOfflineItems()
            LockWifiManager.shared.localCache.checkAndUpdateFactoryReset { (status) in
            }
            //            getServerTimeAPICall()
            self.offset = 0
            self.getLockListServiceCall()
            self.updateLocallyAddedLocks()
            //            self.updateEditedLockList()
            
        } else {
            self.refresher.endRefreshing()
        }
    }
    
    // MARK: - Floating Button
    
    func addFloatingButton() {
        self.actionButton.buttonColor = BUTTON_BGCOLOR
        self.actionButton.addItem(title: "", image: UIImage(named: "add")) { _ in
            self.actionButton.isHidden = true
            self.addLockView.isHidden = false
            self.lockListTableView.isHidden = true
            self.noLocksLabelView.isHidden = true
            //            self.lockDeviceTextField.text = "Select Lock"
        }
        self.actionButton.display(inViewController: self)
    }
    
    // MARK: - UI updates
    
    func updateUIWithFloatingButton() { // show floating btn
        self.addLockView.isHidden = true
        self.actionButton.isHidden = false
        
        if self.lockListArray.count > 0 {
            self.lockListTableView.isHidden = false
            self.noLocksLabelView.isHidden = true
        } else {
            self.lockListTableView.isHidden = true
            self.noLocksLabelView.isHidden = false
        }
    }
    
    func setButtonProperties() {
        self.cancelLockButton.layer.cornerRadius = 10.0
        self.cancelLockButton.layer.borderWidth = 1
        self.cancelLockButton.layer.borderColor = UIColor.darkGray.cgColor
        self.addLockButton.layer.cornerRadius = 10.0
        self.disableLockButton()
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        let nib = UINib(nibName: "LockListTableViewCell", bundle: nil)
        self.lockListTableView.register(nib, forCellReuseIdentifier: "LockListTableViewCell")
    }
    
    // MARK: - Update Addlock UI
    
    func updateAddLockUI() {
        self.lockNameTextField.hideInfo()
        self.lockCodeTextField.hideInfo()
        self.lockNameTextField.text = ""
        self.lockCodeTextField.text = ""
    }
    
    // MARK: - Button Actions
    
    @IBAction func onTapLockCancelButton(_ sender: UIButton) {
        self.view.endEditing(true)
        self.updateAddLockUI()
        self.updateUIWithFloatingButton()
    }
    func validationScartchCode() -> Bool{
        if JsonUtils().getScratchCodePrefix() != "" {
            let firstTwoCharacter = self.lockCodeTextField.text?.prefix(2)
            if firstTwoCharacter ?? "" != JsonUtils().getScratchCodePrefix() {
                self.disableLockButton()
                return false
            }
        }
        return true
    }
    
    @IBAction func onTapLockAddButton(_ sender: UIButton) {
        self.view.endEditing(true)
        
        //Old flow
        /*let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertControllerStyle.alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
         self.checkForWIFI()
         }))
         self.present(alert, animated: true, completion: nil)*/
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        let urlString = ServiceUrl.BASE_URL + "locks/newlock"
        let lockDetails = ["name": self.lockNameTextField.text!, "scratch_code": self.getScartchCode()]
        
        LockDetailsViewModel().addLockViaMqttViewModel(url: urlString, lockDetails: lockDetails, callback: { result, error in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            print("Lck add result: ==> \(String(describing: result))")
           // if result != nil {
          //  if let result = result , result["status"] == "success" {
            if result!["status"] == "success" {
                var ownerId = ""
                var userKey = ""
                var role = UserRoles.user
                
                let lockObj = LockListModel(json: result!["data"].rawValue as! NSDictionary)
                lockObj.lockVersion = result!["data"]["lock_version"].rawValue as? String
                lockObj.lockname = result!["data"]["name"].rawValue as? String
                lockObj.ssid = result!["data"]["ssid"].rawValue as? String
                lockObj.serial_number = result!["data"]["serial_number"].rawValue as? String
                lockObj.scratch_code = result!["data"]["scratch_code"].rawValue as? String
                lockObj.status = result!["data"]["status"].rawValue as? String
                
                lockObj.is_secured = result!["data"]["is_secured"].rawValue as? String ?? "0"
                
                var lockOwnerDetailsArray = [LockOwnerDetailsModel]()
                
                if result!["data"]["lock_owner_id"].count > 0 {
                    let lockOwnerDetailsDict = result!["data"]["lock_owner_id"][0].rawValue as! NSDictionary
                    let lockOwnerDetailsObj = LockOwnerDetailsModel(json: [:])
                    lockOwnerDetailsObj.id = lockOwnerDetailsDict["id"] as? String
                    lockOwnerDetailsObj.slot_number = lockOwnerDetailsDict["slot_number"] as? String
                    lockOwnerDetailsObj.lock_id = lockOwnerDetailsDict["lock_id"] as? String
                    lockOwnerDetailsObj.user_type = lockOwnerDetailsDict["user_type"] as? String
                    lockOwnerDetailsObj.status = lockOwnerDetailsDict["status"] as? String
                    
                    lockOwnerDetailsArray.append(lockOwnerDetailsObj)
                }
                lockObj.lock_owner_id = lockOwnerDetailsArray
                
                var lockKeysArray = [UserLockRoleDetails]()
                if result!["data"]["lock_keys"].count > 0 {
                    for j in 0..<result!["data"]["lock_keys"].count {
                        let userLockDetails = result!["data"]["lock_keys"][j].rawValue as! NSDictionary
                        
                        let userLockRoleDetailsObj = UserLockRoleDetails(json: [:])
                        userLockRoleDetailsObj.id = userLockDetails["id"] as? String
                        userLockRoleDetailsObj.key = userLockDetails["key"] as? String
                        userLockRoleDetailsObj.user_type = userLockDetails["user_type"] as? String
                        userLockRoleDetailsObj.slot_number = userLockDetails["slot_number"] as? String
                        userLockRoleDetailsObj.lock_id = userLockDetails["lock_id"] as? String
                        userLockRoleDetailsObj.status = userLockDetails["status"] as? String
                        userLockRoleDetailsObj.is_schedule_access = userLockDetails["is_schedule_access"] as? String
                        userLockRoleDetailsObj.schedule_date_from = userLockDetails["schedule_date_from"] as? String
                        userLockRoleDetailsObj.schedule_date_to = userLockDetails["schedule_date_to"] as? String
                        userLockRoleDetailsObj.schedule_time_from = userLockDetails["schedule_time_from"] as? String
                        userLockRoleDetailsObj.schedule_time_to = userLockDetails["schedule_time_to"] as? String
                        userLockRoleDetailsObj.userID = userLockDetails["user_id"] as? String
                        
                        if userLockRoleDetailsObj.isTypeOwnerID(){
                            ownerId = userLockRoleDetailsObj.key
                        }
                        else {
                            userKey = userLockRoleDetailsObj.key
                            role = userLockRoleDetailsObj.userRoleType()
                            
                        }
                        lockKeysArray.append(userLockRoleDetailsObj)
                    }
                }
                if let lockSerialNumber = lockObj.serial_number {
                    UserController.sharedController.save(ownerId: ownerId, userKey: userKey, userRole: role, serialNumber: lockSerialNumber)
                } else {
                    // Handle the case where lockObj.serial_number is nil
                    print("Error: Serial number already exists.")
                }
//                UserController.sharedController.save(ownerId: ownerId, userKey: userKey, userRole: role,serialNumber: lockObj.serial_number)
              
                lockObj.lock_keys = lockKeysArray
                print(lockObj)
                
                self.view.endEditing(true)
                self.updateAddLockUI()
                self.updateUIWithFloatingButton()
                
                Utilities.showSuccessAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
                self.getLockListServiceCall()
                
                if (lockObj.lockVersion != nil && lockObj.lockVersion == lockVersions.version4_0.rawValue){
                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let homeWifiConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "HomeWifiConfigurationViewController") as! HomeWifiConfigurationViewController
                    homeWifiConfigurationViewController.userLockID = lockObj.lock_keys[1].lock_id!
                    homeWifiConfigurationViewController.scratchCode = lockObj.scratch_code
                    //homeWifiConfigurationViewController.lockConnection.selectedLock =  self.lockConnection.selectedLock
                    homeWifiConfigurationViewController.lockConnection.serialNumber = lockObj.serial_number
                    homeWifiConfigurationViewController.lockListDetailsObj = lockObj
                    self.navigationController?.pushViewController(homeWifiConfigurationViewController, animated: true)
                }
            } else {
                let message = result?["message"].string
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - Navigation methods
    
    func navigateToDeviceSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                //print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    func disconnectWifi(ssid: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: newSSID)
        }
    }
    
    // MARK: -  Add lock
    
    
    func connectDeviceToBLE() {
        
        if self.availableListOfLockCount-1 > recentlyProcessedLockIndex {
            
            recentlyProcessedLockIndex = recentlyProcessedLockIndex+1
            self.lockConnection.selectedLock = availableListOfLock[recentlyProcessedLockIndex]
            if self.lockConnection.isLockFound {
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedByBLE {
                    //print("self.lockConnection.selectedLock! ==> inside isConnectedByBLE ==> ")
                    //print(self.lockConnection.selectedLock!)
                    BLELockAccessManager.shared.connectWithLock(lockData: self.lockConnection.selectedLock!)
                }
            } else {
                Utilities.showErrorAlertView(message: "lock not found", presenter: self)
            }
        } else {
            
            // Navigate to WIFI
        }
        
    }
    
    
    func addLock() {
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        
        if self.lockConnection.isConnectedToLockWifi() == true {
            
            let ssid  = lockConnection.ssid
            
            /*LoaderView.sharedInstance.showShadowView(title: "Connecting by Wifi", selfObject: self)
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             // your code here
             LoaderView.sharedInstance.hideShadowView(selfObject: self)
             }*/
            self.lockDeviceTextField.text = ssid!
            self.lockConnection.isConnectedByBLE = false
            self.lockConnection.ssid = ssid
            
            
            LockWifiManager.shared.activateLock(activationCode: self.getScartchCode(), completion: {[weak self](isSuccess, json, error) in
                guard let self = self else { return }
                if let jsonDict = json?.dictionary {
                    let dictResponse = jsonDict["response"]?.dictionaryObject!
                    //print("Response ==> from wifi manager ==>>> ")
                    //print(dictResponse)
                    let lockHardwareData = LockWifiApiTransformer.transformActivateResponseToLockHardwareData(response: dictResponse! as [String : AnyObject])
                    print("lockHardwareData ==> ")
                    //print(lockHardwareData)
                    //print(lockHardwareData.macAddress)
                    //print("------------------------------")
                    if lockHardwareData.slotKeyArray.isEmpty{
                        Utilities.showErrorAlertView(message: "Activate lock failed", presenter: self)
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                        return
                    }
                    let serialNumber = self.lockDeviceTextField.text!
                    lockHardwareData.ssid = serialNumber
                    let lockListModel = lockHardwareData.convertToLockListModel(lockName: self.lockNameTextField.text!, scratchCode: self.getScartchCode())
                    UserController.sharedController.save(ownerId: lockHardwareData.lockOwnerIdForWifi() ?? "", userKey: lockHardwareData.lockOwnerKeyForWifi() ?? "", userRole: .owner, serialNumber: serialNumber)
                    lockListModel.lockListDetails.wasAddedOffline = true
                    print("addLock ==> saveLockInLocal called")
                    self.saveLockInLocal(addLockObj: lockListModel)
                    self.lockConnection.hardwareData = lockHardwareData
                    self.lockConnection.isConnectedByBLE = false
                    self.isAddButtonTapped = false
                    Utilities.showErrorAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                }
                else if isSuccess == false {
                    Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                }
            })
        } else {
            
            self.isAddLockScanning = true
            
            initializeScan()
        }
    }
    
    func addLockViaBLE() {
        
        isReadAllKeys = false
        //print("triedBLEDeviceList ==> ")
        //print(self.triedBLEDeviceList)
        if self.triedBLEDeviceList.count > 0 {
            
            let tempArr = self.availableListOfLock.filter { self.triedBLEDeviceList.contains($0.formattedLocalName) }
            
            //print("tempArr ==> ")
            //print(tempArr)
            if tempArr.count > 0 {
                
                if self.availableListOfLock.count > 0 {
                    if let i = self.availableListOfLock.index(where: { $0.formattedLocalName == tempArr[0].formattedLocalName }) {
                        //print("Index ==> \(i)")
                        let objectIndex = i
                        
                        self.availableListOfLock.remove(at: objectIndex)
                        
                        //print("availableListOfLock ==> ")
                        //print(self.availableListOfLock)
                    }
                }
            }
        }
        
        self.availableListOfLockCount = self.availableListOfLock.count
        
        
        if self.availableListOfLockCount > 0 {
            self.lockConnection.selectedLock = self.availableListOfLock[0]
            self.recentlyProcessedLockIndex = 0
            if self.lockConnection.isLockFound {
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedByBLE {
                    //print("self.lockConnection.selectedLock! ==> inside isConnectedByBLE ==> ")
                    //print(self.lockConnection.selectedLock!)
                    BLELockAccessManager.shared.connectWithLock(lockData: self.lockConnection.selectedLock!)
                }
            } else {
                Utilities.showErrorAlertView(message: "lock not found", presenter: self)
            }
        }
        
    }
    var isShowDialog:Bool=false
    
    
    func checkForWIFI() {
        
        isAddButtonTapped = true
        //print("self.isConnectedViaWIFI ==> ")
        //print(self.isConnectedViaWIFI)
        let connectivityTime = JsonUtils().getScratchCodePrefix().count != 0 ? 20.0 : self.lockCodeTextField.text?.count == 9 ? 20.0 : 13.0
        DispatchQueue.main.asyncAfter(deadline: .now() + connectivityTime, execute: {
            print("BLE isConnectedViaWIFI ===>>>>>> \(self.isConnectedViaWIFI)")
            if !self.isConnectedViaWIFI {
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    self.initializeScan()
                    print("BLE initialized?")
                }  else {
                   // Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
            }
        })
        //        if #available(iOS 14.0, *) {
        //            print("OS 14 and Above")
        //            if !isShowDialog{
        //                isShowDialog=true
        //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
        //                self.isConnectedViaWIFI = false
        //                 let message = SETTINGS_NAVIGATION
        //                 let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
        //                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        //                 }))
        //                 self.present(alert, animated: true, completion: nil)
        //            }else{
        //                isShowDialog=false
        //                self.lockConnection.ssid="Astrix_"
        //                print("call add lock")
        //                self.addLockViaConnectedWIFI()
        //            }
        //        }else{
        print("self.lockConnection.isConnectedToLockWifi() ===>>> \(self.lockConnection.isConnectedToLockWifi())")
        if hasLocationPermission() == true{
            print("hasLocationPermission")
            
            if self.lockConnection.isConnectedToLockWifi() == true {
                print("call add lock")
                self.addLockViaConnectedWIFI()
            } else {
                self.isConnectedViaWIFI = false
                let message = SETTINGS_NAVIGATION
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else{
            
            let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
                //Redirect to Settings app
                UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString/*.UIApplicationOpenSettingsURLString*/)!)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
            alertController.addAction(cancelAction)
            
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        
        
        //}
    }
    
    func hasLocationPermission() -> Bool {
        var hasPermission = false
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    hasPermission = false
                case .authorizedAlways, .authorizedWhenInUse:
                    hasPermission = true
            }
        } else {
            hasPermission = false
        }
        
        return hasPermission
    }
    
    func addLockViaConnectedWIFI() {
        
        print("addLockViaConnectedWIFI ==> @@@@@@@@@@@@@@@@")
        let ssid  = lockConnection.ssid
        
        /*LoaderView.sharedInstance.showShadowView(title: "Connecting by Wifi", selfObject: self)
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
         // your code here
         LoaderView.sharedInstance.hideShadowView(selfObject: self)
         }*/
        self.lockDeviceTextField.text = ssid!
        self.lockConnection.isConnectedByBLE = false
        self.lockConnection.ssid = ssid
        
        LockWifiManager.shared.activateLock(activationCode: self.getScartchCode(), completion: {[weak self](isSuccess, json, error) in
            guard let self = self else { return }
            //print("Wifi response ==> ")
            //print(isSuccess)
            //print(json)
            //print(error)
            //print("#########################")
            self.isConnectedViaWIFI = true
            
            if let jsonDict = json?.dictionary {
                
                let dictResponse = jsonDict["response"]?.dictionaryObject!
                let lockHardwareData = LockWifiApiTransformer.transformActivateResponseToLockHardwareData(response: dictResponse! as [String : AnyObject])
                if lockHardwareData.slotKeyArray.isEmpty{
                    Utilities.showErrorAlertView(message: "Activate lock failed", presenter: self)
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    return
                }
                print("Inside Add lock")
                print("\(lockHardwareData.lockVersion)")
                let serialNumber = self.lockDeviceTextField.text!
                lockHardwareData.ssid = serialNumber
                let lockListModel = lockHardwareData.convertToLockListModel(lockName: self.lockNameTextField.text!, scratchCode: self.getScartchCode())
                UserController.sharedController.save(ownerId: lockHardwareData.lockOwnerIdForWifi() ?? "", userKey: lockHardwareData.lockOwnerKeyForWifi() ?? "", userRole: .owner, serialNumber: serialNumber)
                lockListModel.lockListDetails.wasAddedOffline = true
                lockListModel.lockListDetails.lockVersion = lockHardwareData.lockVersion
                
                self.lockConnection.hardwareData = lockHardwareData
                self.lockConnection.isConnectedByBLE = false
                self.isAddButtonTapped = false
                self.disconnectWifi(ssid: self.lockConnection.serialNumber)
                print("addLockViaConnectedWIFI ==> saveLockInLocal called")
                self.saveLockInLocal(addLockObj: lockListModel)
                print("Addlock WIFI ============")
                print(jsonDict)
                Utilities.showErrorAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
            else if isSuccess == false {
                Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
        })
    }
    
    func addLockViaWIFI() {
        LockWifiManager.shared.activateLock(activationCode: self.getScartchCode(), completion: {[weak self](isSuccess, json, error) in
            guard let self = self else { return }
            if let jsonDict = json?.dictionary {
                let dictResponse = jsonDict["response"]?.dictionaryObject!
                let lockHardwareData = LockWifiApiTransformer.transformActivateResponseToLockHardwareData(response: dictResponse! as [String : AnyObject])
                if lockHardwareData.slotKeyArray.isEmpty{
                    Utilities.showErrorAlertView(message: "Activate lock failed", presenter: self)
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    return
                }
                let serialNumber = self.lockDeviceTextField.text!
                lockHardwareData.ssid = serialNumber
                let lockListModel = lockHardwareData.convertToLockListModel(lockName: self.lockNameTextField.text!, scratchCode: self.getScartchCode())
                UserController.sharedController.save(ownerId: lockHardwareData.lockOwnerIdForWifi() ?? "", userKey: lockHardwareData.lockOwnerKeyForWifi() ?? "", userRole: .owner, serialNumber: serialNumber)
                lockListModel.lockListDetails.wasAddedOffline = true
                print("addLockViaWIFI ==> saveLockInLocal called")
                self.lockConnection.hardwareData = lockHardwareData
                self.lockConnection.isConnectedByBLE = false
                self.isAddButtonTapped = false
                self.saveLockInLocal(addLockObj: lockListModel)
                
                Utilities.showErrorAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
            else if isSuccess == false {
                Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
        })
    }
    
    func saveLockLocalAddedViaBLE(lockHardwareData: LockHardwareDetails) {
        
        let hardwareData = lockConnection.hardwareData!
        var localPeripheralName = hardwareData.lockAdvertisementData?.peripheral?.name
        localPeripheralName = localPeripheralName?.replacingOccurrences(of: JsonUtils().getManufacturerCode(), with: "")
        
        lockHardwareData.ssid = localPeripheralName!
        let lockListModel = lockHardwareData.convertToLockListModel(lockName: self.lockNameTextField.text!, scratchCode: self.getScartchCode())
        UserController.sharedController.save(ownerId: lockHardwareData.lockOwnerIdForWifi() ?? "", userKey: lockHardwareData.lockOwnerKeyForWifi() ?? "", userRole: .owner, serialNumber: localPeripheralName!)
        lockListModel.lockListDetails.wasAddedOffline = true
        print("saveLockLocalAddedViaBLE ==> saveLockInLocal called")
        self.saveLockInLocal(addLockObj: lockListModel)
        self.lockConnection.hardwareData = lockHardwareData
        self.lockConnection.isConnectedByBLE = false
        isAddButtonTapped = false
        Utilities.showErrorAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
        LoaderView.sharedInstance.hideShadowView(selfObject: self)
        
        
    }
    
    // MARK: - Add lock old code
    func addLockOldCode() {
        if self.lockConnection.isLockFound {
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            if self.lockConnection.isConnectedByBLE{
                BLELockAccessManager.shared.connectWithLock(lockData: self.lockConnection.selectedLock!)
            }
            else{
                LockWifiManager.shared.activateLock(activationCode: self.getScartchCode(), completion: {[weak self](isSuccess, json, error) in
                    guard let self = self else { return }
                    if let jsonDict = json?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let lockHardwareData = LockWifiApiTransformer.transformActivateResponseToLockHardwareData(response: dictResponse! as [String : AnyObject])
                        if lockHardwareData.slotKeyArray.isEmpty{
                            Utilities.showErrorAlertView(message: "Activate lock failed", presenter: self)
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            return
                        }
                        let serialNumber = self.lockDeviceTextField.text!
                        lockHardwareData.ssid = serialNumber
                        let lockListModel = lockHardwareData.convertToLockListModel(lockName: self.lockNameTextField.text!, scratchCode: self.getScartchCode())
                        UserController.sharedController.save(ownerId: lockHardwareData.lockOwnerIdForWifi() ?? "", userKey: lockHardwareData.lockOwnerKeyForWifi() ?? "", userRole: .owner, serialNumber: serialNumber)
                        lockListModel.lockListDetails.wasAddedOffline = true
                        
                        self.lockConnection.hardwareData = lockHardwareData
                        self.lockConnection.isConnectedByBLE = false
                        print("addLockOldCode ==> saveLockInLocal called")
                        self.saveLockInLocal(addLockObj: lockListModel)
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    }
                    else if isSuccess == false {
                        Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    }
                })
            }
        }
        else {
            Utilities.showErrorAlertView(message: "Please select a lock", presenter: self)
        }
    }
    
    func processAddLock(){
        
        var dbObject = CoreDataController()
        
        if Connectivity().isConnectedToInternet(){
            self.addLockDetailsServiceCall()
        } else {
            self.updateAddLockUI()
            //  if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
            if let lockListArr = dbObject.fetchLockList() as? [LockListModel]{
                //                        user = savedUser
                //print("savedUser ==> \(lockListArr)")
                self.lockListArray = lockListArr
            } else {
            }
            //}
            
            self.actionButton.isHidden = false
            if self.lockListArray.count > 0 {
                self.noLocksLabelView.isHidden = true
                self.addLockView.isHidden = true
                self.lockListTableView.isHidden = false
            } else {
                self.noLocksLabelView.isHidden = false
                self.addLockView.isHidden = true
                self.lockListTableView.isHidden = true
            }
            self.lockListTableView.reloadData()
        }
    }
    
    // MARK: - Add locally added lock
    
    func updateLocallyAddedLocks() {
        // Update addLockList userdefaults
        
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if var addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //print("updateLocallyAddedLocks savedUser ==> \(addLockListArr)")
                
                for i in 0..<addLockListArr.count {
                    // service call
                    self.addOfflineLockDetailsServiceCall(addLockObj: addLockListArr[i])
                }
            }
        }
    }
    
    func updateEditedLockList() {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.editLockNameList.rawValue) as? NSData {
            if var editLockNameListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
                //print("updateLocallyAddedLocks savedUser ==> \(editLockNameListArr)")
                
                for i in 0..<editLockNameListArr.count {
                    // service call
                    self.updateEditLockDetailsServiceCall(editLockNameObj: editLockNameListArr[i])
                }
            }
        }
    }
    
    func saveLockInLocal(addLockObj:AddLockModel) {
        let lockDetails = addLockObj.lockListDetails!
        
        let localDB = CoreDataController()
        if var lockListArr = localDB.fetchLockList() as? [LockListModel] {
            let tmpArray = lockListArr.filter { $0.serial_number! == lockDetails.serial_number! }
            
            if tmpArray.count > 0 {
                // alert lock already added
                let message = "Lock already exist"
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
                
            } else { // add lock in list
                if lockListArr.count > 0 {
                    lockListArr.insert(lockDetails, at: 0)
                    self.localDataArchive(lockListArr: lockListArr)
                } else {
                    lockListArr.append(lockDetails)
                    self.localDataArchive(lockListArr: lockListArr)
                }
            }
        }else{
            var tempArr = [LockListModel]()
            tempArr.append(lockDetails)
            self.localDataArchive(lockListArr: tempArr)
        }
        
        
        // Update addLockList userdefaults
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if var addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //                        user = savedUser
                //print("savedUser ==> \(self.lockListArray)")
                // check for serial_number
                
                let tmpArray = addLockListArr.filter { $0.lockListDetails.serial_number! == lockDetails.serial_number! }
                
                if tmpArray.count > 0 {
                    // alert lock already added
                    let message = "Lock already exist"
                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                } else { // add lock in list
                    if addLockListArr.count > 0 {
                        addLockListArr.insert(addLockObj, at: 0)
                        self.localAddLockDataArchive(lockListArr: addLockListArr)
                    } else {
                        addLockListArr.append(addLockObj)
                        self.localAddLockDataArchive(lockListArr: addLockListArr)
                    }
                }
                
            } else { // Add new key
                var tempArr = [AddLockModel]()
                tempArr.append(addLockObj)
                self.localAddLockDataArchive(lockListArr: tempArr)
            }
        } else {
            var tempArr = [AddLockModel]()
            tempArr.append(addLockObj)
            self.localAddLockDataArchive(lockListArr: tempArr)
        }
        self.processAddLock()
    }
    
    func localDataArchive(lockListArr: [LockListModel]) {
        //Push data to LocalDB
        let localDB = CoreDataController()
        
        for lock in lockListArr{
            let isPassageModeEnabled = (lock.enable_passage == "1")
            let passageModeSwitch = UISwitch()
            passageModeSwitch.isOn = isPassageModeEnabled
            let success = localDB.saveLock(lockobject: lock, passageModeSwitch: passageModeSwitch)
        }
        
        
        //        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: lockListArr)
        //        let defaults = UserDefaults.standard
        //        defaults.set(archivedObject, forKey: UserdefaultsKeys.usersLockList.rawValue)
        //        defaults.synchronize()
    }
    
    func localAddLockDataArchive(lockListArr: [AddLockModel]) {
        if Connectivity().isConnectedToInternet() {
            
        } else {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: lockListArr)
            let defaults = UserDefaults.standard
            defaults.set(archivedObject, forKey: UserdefaultsKeys.addLockList.rawValue)
            defaults.synchronize()
        }
    }
    
    // MARK: - TextField Delegates
    
    @IBAction func lockNameDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        self.lockNameTextField.hideInfo()
    }
    
    @IBAction func lockNameDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text == "" {
            sender.showInfo(LOCKNAME_MANDATORY_ERROR)
        } else {
            self.validation()
            return
        }
    }
    
    @IBAction func lockCodeDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        self.lockCodeTextField.hideInfo()
    }
    
    @IBAction func lockCodeDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text == "" {
            sender.showInfo(LOCKCODE_MANDATORY_ERROR)
        }else if ScratchCodeValidationCount <= self.lockCodeTextField.text?.count ?? 0{
            if self.validationScartchCode(){
                self.validation()
                return
            }else{
                sender.showInfo(INVALID_LOCK_CODE)
            }
        }
        //        else if ScartchCodeValidationCount <= sender.text!.count {
        //            if ScartchCodePrefix != "" {
        //                let firstTwoCharacter = sender.text?.prefix(2)
        //                if firstTwoCharacter ?? "" == ScartchCodePrefix {
        //                    self.validation()
        //                } else {
        //                    self.disableLockButton()
        //                    sender.showInfo(LOCKCODE_VALID_ERROR)
        //                }
        //            } else {
        //            self.validation()
        //            return
        //            }
        //        }
        else {
            sender.showInfo(LOCKCODE_VALID_ERROR)
        }
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return self.itemInfo
    }
    
    // MARK: - Validation
    
    func validation() {
        self.disableLockButton()
        if (self.lockNameTextField.text?.isEmpty)! {
        } else if (self.lockCodeTextField.text?.isEmpty)! {
        } else if (self.lockCodeTextField.text?.count)! < ScratchCodeValidationCount {
        } else {
            if self.validationScartchCode(){
                self.enableLockButton()
            }
            
        }
    }
    
    func disableLockButton(){
        self.addLockButton.isEnabled = false
        self.addLockButton.isUserInteractionEnabled = false
        self.addLockButton.backgroundColor = UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 0.6)
    }
    func enableLockButton() {
        self.addLockButton.isEnabled = true
        self.addLockButton.isUserInteractionEnabled = true
        self.addLockButton.backgroundColor = UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 1.0)
    }
    
    // MARK: - Service call
    
    @objc func getLockListServiceCall() {
        print("get lock list ")
        //        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let notificationPaginationString = notificationPagination.paginationString()
        if notificationPagination.shouldStopPaginate == true {
            return
        }
        //        let urlString = ServiceUrl.BASE_URL + "locks/locklist?\(notificationPagination)"
        // existing
        //        let urlString = ServiceUrl.BASE_URL + "locks/locklist"
        // new for factory
        let paginationString = "?limit=\(limit)&offset=\(offset)"
        let urlString = ServiceUrl.BASE_URL + "locks/locklist\(paginationString)"
        //        http://103.238.231.140/api/web/v1/locks/locklist?limit=20&offset=0
        
        if offset==0{
            let locaDB = CoreDataController()
            locaDB.deleteAllData()
        }
        LockDetailsViewModel().getLockListServiceViewModel(url: urlString, userDetails: [:]) { result, _ in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            print("resultCount = \(String(describing: result?.count))")
            print("result = \(String(describing: result))")
            
            if result!.count < self.limit{
                self.allDataFetched = true
            }
            
            //            print(result)
            if result != nil {
                
                if self.offset == 0 {
                    self.lockListArray.removeAll()
                    self.lockListArray = result as! [LockListModel]
                }
                else{
                    
                    for i in result as! [LockListModel]{
                        self.lockListArray.append(i)
                    }
                }
                var tempLockListArray = [LockListModel]()
                
                for lockObj in self.lockListArray {
                    
                    if lockObj.lock_keys.count > 0 {
                        var userObj = UserLockRoleDetails(json: [:])
                        userObj = lockObj.lock_keys[1] as UserLockRoleDetails
                        
                        print(lockObj)
                        if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                            
                            let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
                            let startDateString = Utilities().toDateString(date: startDate)
                            
                            let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
                            let endDateString = Utilities().toDateString(date: endDate)
                            
                            let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                            let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                            
                            let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                            let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                            let currentDate = NSDate()
                            let currentDateString = dateFormatter.string(from: currentDate as Date)
                            
                            let currentDateNew = Utilities().toDate(dateString: currentDateString)
                            let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                            
                            let dateFormatter1 = DateFormatter()
                            dateFormatter1.dateFormat = "HH:mm"
                            let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                            
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd-MM-yyyy"
                            let firstDate = formatter.date(from: startDateString)
                            let secondDate = formatter.date(from: currentDateStringNew)
                            
                            if (firstDate?.compare(secondDate!) == .orderedAscending || firstDate?.compare(secondDate!) == .orderedSame) && currentDateStringNew <= endDateString {
                                print("First Date is smaller then second date")
                                tempLockListArray.append(lockObj)
                            }
                            
                            //                        if startDateString <= currentDateStringNew && currentDateStringNew <= endDateString {
                            //                            tempLockListArray.append(lockObj)
                            //                        }
                            
                        } else {
                            tempLockListArray.append(lockObj)
                        }
                    }
//                    if let passageModeState = UserDefaults.standard.bool(forKey: "enable_passage_\(lockObj.id)") {
//                                // Update enable_passage property of the LockListModel object
//                                lockObj.enable_passage = passageModeState ? "1" : "0"
//                                if let index = self.lockListArray.firstIndex(where: { $0.id == lockObj.id }) {
//                                    // Update the lock object in the array
//                                    self.lockListArray[index] = lockObj
//                                } else {
//                                    print("Error: Lock object not found in lockListArray")
//                                }
//                                print("Passage mode state retrieved successfully for lock \(lockObj.id): \(passageModeState)")
//                                print("enable_passage: \(String(describing: lockObj.enable_passage))")
//                            } else {
//                                print("Passage mode state not found in UserDefaults for lock \(lockObj.id)")
//                            }
//                   
                        if let passageModeState = LockDetailsViewController().retrievePassageModeState(for: lockObj.id) {
                            // Update enable_passage property of the LockListModel object
                            lockObj.enable_passage = passageModeState ? "1" : "0"
                            if let index = self.lockListArray.firstIndex(where: { $0.id == lockObj.id }) {
                                    // Update the lock object in the array
                                    self.lockListArray[index] = lockObj
                                } else {
                                    print("Error: Lock object not found in lockListArray")
                                }
                            print("Passage mode state retrieved successfully for lock \(lockObj.id): \(passageModeState)")
                            print("enable_passage: \(String(describing: lockObj.enable_passage))")
                        } else {
                            print("passage mode is not updated")
                        }
                    
                }
                
                
                self.lockListArray = tempLockListArray
                
                
                
                self.actionButton.isHidden = false
                if self.lockListArray.count > 0 {
                    self.noLocksLabelView.isHidden = true
                    self.addLockView.isHidden = true
                    self.lockListTableView.isHidden = false
                } else {
                    self.noLocksLabelView.isHidden = false
                    self.addLockView.isHidden = true
                    self.lockListTableView.isHidden = true
                }
                DispatchQueue.main.async {
                            self.lockListTableView.reloadData()
                            print("Table updated")
                        }
//                self.lockListTableView.reloadData()
//                print("table updated")
                
            } else {
                /*
                 let message = error?.userInfo["ErrorMessage"] as! String
                 let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                 
                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                 }))
                 self.present(alert, animated: true, completion: nil)
                 */
            }
        }
    }
    
    func addLockDetailsServiceCall() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        let hardwareData = lockConnection.hardwareData!
        let slotKeyArray = hardwareData.slotDataAsKVPair()
        let ownerIdArray = hardwareData.lockOwnerIdAsKVPair()
        let urlString = ServiceUrl.BASE_URL + "locks/addlock"
        var localPeripheralName = hardwareData.lockAdvertisementData?.peripheral?.name
        localPeripheralName = localPeripheralName?.replacingOccurrences(of: JsonUtils().getManufacturerCode(), with: "")
        print("Add lock ==> \(hardwareData.macAddress)")
        var userDetails = [
            "name": self.lockNameTextField.text!,
            "uuid": hardwareData.macAddress, // BLE address ==> check rssi ?
            "ssid": localPeripheralName ?? "", // WIFI
            // "serial_number": "\(arc4random_uniform(1000))", // BLE serial number
            "serial_number": localPeripheralName ?? "", // BLE serial number
            "scratch_code": self.getScartchCode() , //
            "status": "1",
            "lock_keys": slotKeyArray,
            "lock_ids": ownerIdArray,
            "is_secured":"1",
            "lock_version": hardwareData.lockVersion
        ] as [String: Any]
        
        if hardwareData.lockVersion == lockVersions.version2_0.rawValue || hardwareData.lockVersion == lockVersions.version2_1.rawValue || hardwareData.lockVersion == lockVersions.version3_0.rawValue || hardwareData.lockVersion == lockVersions.version3_1.rawValue{
            userDetails["rfid"] = Utilities().getRFIDs()
        }
        
        print("addLockDetailsServiceCall =======>> lock_version ====> \(hardwareData.lockVersion)")
        
        /*
         "lock_version":"v2.0","name":"LockFP2","rfid":[{"key":"0","name":"RFID 1","slot_number":"0"},{"key":"1","name":"RFID 2","slot_number":"1"},{"key":"2","name":"RFID 3","slot_number":"2"}],
         */
        
        LockDetailsViewModel().addLockDetailsServiceViewModel(url: urlString, userDetails: userDetails as [String: Any]) { result, error in
            
            print("Result ==> \(String(describing: result))")
            if result != nil {
                // populate data from result and reload table
                
                // success
                // if result empty lockListArray < 0
                
                //if success add in db
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // your code here
                    self.isAddButtonTapped = false
                    Utilities.showSuccessAlertView(message: ADD_LOCK_SCCESS_MESSAGE, presenter: self)
                }
                
                self.updateAddLockUI()
                self.offset = 0
                self.getLockListServiceCall()
                
                self.actionButton.isHidden = false
                if self.lockListArray.count > 0 {
                    self.noLocksLabelView.isHidden = true
                    self.addLockView.isHidden = true
                    self.lockListTableView.isHidden = false
                } else {
                    self.noLocksLabelView.isHidden = false
                    self.addLockView.isHidden = true
                    self.lockListTableView.isHidden = true
                }
                
            } else {
                if !self.isAddLockServiceFailed {
                    self.saveLockLocalAddedViaBLE(lockHardwareData: self.lockConnection.hardwareData!)
                    
                } else {
                    self.updateAddLockUI()
                    //                    if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
                    var dbObj = CoreDataController()
                    if let lockListArr =  dbObj.fetchLockList() as? [LockListModel] {
                        //                        user = savedUser
                        //print("savedUser ==> \(lockListArr)")
                        self.lockListArray = lockListArr
                    } else {
                    }
                    // }
                    
                    self.actionButton.isHidden = false
                    if self.lockListArray.count > 0 {
                        self.noLocksLabelView.isHidden = true
                        self.addLockView.isHidden = true
                        self.lockListTableView.isHidden = false
                    } else {
                        self.noLocksLabelView.isHidden = false
                        self.addLockView.isHidden = true
                        self.lockListTableView.isHidden = true
                    }
                    self.lockListTableView.reloadData()
                    
                }
                
                self.isAddLockServiceFailed = true
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
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
    
    func addOfflineLockDetailsServiceCall(addLockObj: AddLockModel) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/addlock"
        
        var userDetails = [
            "name": addLockObj.lockListDetails.lockname! as String,
            "uuid": addLockObj.lockListDetails.uuid! as String, // BLE address ==> check rssi ?
            "ssid": addLockObj.lockListDetails.serial_number as String, // WIFI
            "serial_number": addLockObj.lockListDetails.serial_number! as String, // BLE serial number
            "scratch_code": addLockObj.lockListDetails.scratch_code! as String,
            "status": addLockObj.lockListDetails.status! as String,
            "lock_keys": addLockObj.lock_keys,
            "lock_ids": addLockObj.lock_ids,
            "is_secured":"1",
            "lock_version": addLockObj.lockListDetails.lockVersion! as String
        ] as [String: Any]
        
        print("addOfflineLockDetailsServiceCall =======>> lock_version ====> \(addLockObj.lockListDetails.lockVersion)")
        
        if addLockObj.lockListDetails.lockVersion == lockVersions.version2_0.rawValue ||
            addLockObj.lockListDetails.lockVersion == lockVersions.version2_1.rawValue || addLockObj.lockListDetails.lockVersion == lockVersions.version3_0.rawValue || addLockObj.lockListDetails.lockVersion == lockVersions.version3_1.rawValue{
            userDetails["rfid"] = Utilities().getRFIDs()
        }
        
        LockDetailsViewModel().addLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, _ in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // remove this data obj in userdefaults
                
                self.updateAddLockList(addLockObj: addLockObj)
                self.offset = 0
                self.getLockListServiceCall()
                
            } else {
                //                self.saveLockInLocal(addLockObj: addLockObj)
                /*
                 let message = error?.userInfo["ErrorMessage"] as! String
                 let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                 
                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                 }))
                 self.present(alert, animated: true, completion: nil)
                 */
            }
        }
    }
    
    func updateEditLockDetailsServiceCall(editLockNameObj: LockListModel) {
        let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(editLockNameObj.id!)"
        
        let userDetails = [
            "name": editLockNameObj.lockname!
        ]
        
        LockDetailsViewModel().updateLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            //            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // remove obj from editlocknamelist
                // update lock list
                
                //                self.removeEditLockNameObj(editLockObj: editLockNameObj)
                self.getLockListServiceCall()
                
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
    
    // MARK: - Remove Added lock in userdefaults
    
    func updateAddLockList(addLockObj: AddLockModel) {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if var addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //                        user = savedUser
                //print("savedUser ==> \(addLockListArr)")
                // check for serial_number
                
                let tmpArray = addLockListArr.filter { $0.lockListDetails.serial_number! == addLockObj.lockListDetails.serial_number! }
                
                var objectIndex = Int()
                
                var addLockListTempArray = addLockListArr
                
                if let i = addLockListTempArray.index(where: { $0.lockListDetails.serial_number! == addLockObj.lockListDetails.serial_number! }) {
                    //print("Index ==> \(i)")
                    objectIndex = i
                    
                    addLockListTempArray.remove(at: objectIndex)
                    print("addLockListTempArray ==>  count ==> \(addLockListTempArray.count)")
                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: addLockListTempArray)
                    let defaults = UserDefaults.standard
                    defaults.set(archivedObject, forKey: UserdefaultsKeys.addLockList.rawValue)
                    defaults.synchronize()
                }
            }
        }
    }
    
    //    func removeEditLockNameObj(editLockObj: LockListModel) {
    //        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.editLockNameList.rawValue) as? NSData {
    //            if var editLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
    //                //                        user = savedUser
    //                //print("savedUser ==> \(editLockListArr)")
    //                // check for serial_number
    //
    //                let tmpArray = editLockListArr.filter { $0.serial_number! == editLockObj.serial_number! }
    //
    //                var objectIndex = Int()
    //
    //                var editLockListTempArray = editLockListArr
    //
    //                if let i = editLockListTempArray.index(where: { $0.serial_number! == editLockObj.serial_number! }) {
    //                    //print("Index ==> \(i)")
    //                    objectIndex = i
    //
    //                    editLockListTempArray.remove(at: objectIndex)
    //
    //                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: editLockListTempArray)
    //                    let defaults = UserDefaults.standard
    //                    defaults.set(archivedObject, forKey: UserdefaultsKeys.editLockNameList.rawValue)
    //                    defaults.synchronize()
    //                }
    //            }
    //        }
    //    }
}

// MARK: - UITableview

extension LockListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK： UITableViewDataSource
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print("self.lockListArray.count = \(self.lockListArray.count)")
        if self.lockListArray.count - 1 == indexPath.row{
            if allDataFetched == false{
                
                self.offset = self.offset + 1
                print("paginate with offset \(self.offset)")
                getLockListServiceCall()
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if (indexPath as NSIndexPath).section == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "LockListTableViewCell") as? LockListTableViewCell
//            cell?.selectionStyle = .none
//            //            cell?.backgroundColor = UIColor.white
//            //            cell?.lockNameLabel.text = lockListArray[indexPath.row]
//            let lockListObj = lockListArray[indexPath.row]
//            cell?.lockNameLabel.text = lockListObj.lockname
//            
//            print("lockListObj. ===> \(lockListObj.lockVersion)")
//            
//            if lockListObj.lock_keys.count > 0 {
//                var userObj = UserLockRoleDetails(json: [:])
//                userObj = lockListObj.lock_keys[1] as UserLockRoleDetails
//                
//                if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
//                    
////                    let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
////                    let startDateString = Utilities().toDateString(date: startDate)
////                    
////                    let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
////                    let endDateString = Utilities().toDateString(date: endDate)
////                    
////                    let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
////                    let startTimeString = Utilities().to24HoursTimeString(date: startTime)
////                    
////                    var endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
////                    var endTimeString = Utilities().to24HoursTimeString(date: endTime)
//                    let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
//                   // print("start Date for lock list Access \(startDate)")
//                    let startDateString = Utilities().toDateString(date: startDate)
//                    print("start Date string for lock list Access \(startDateString)")
//                    
//                    let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
//                  //  print("end Date for lock list Access \(endDate)")
//                    let endDateString = Utilities().toDateString(date: endDate)
//                    print("end Date string for lock list Access \(endDateString)")
//
//                    let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
//                    let startTimeString = Utilities().to24HoursTimeString(date: startTime)
//                    print("start time string for lock access \(startTimeString)")
//                    
//                    var endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
//                    var endTimeString = Utilities().to24HoursTimeString(date: endTime)
//                    print("end time string for lock access \(endTimeString)")
//                    
//                    let startDateTimeString = "\(startDateString) \(startTimeString)"
//                    print("start date time string \(startDateTimeString)")
//                    let endDateTimeString = "\(endDateString) \(endTimeString)"
//                    print("end date time string \(endDateTimeString)")
//                    
//                   // if startTime > endTime
//                    if startTimeString > endTimeString
//                    {
//                        endTime = Calendar.current.date(byAdding: .day, value: 1, to: endTime)!
//                        print(endTime)
//                        endTimeString = Utilities().to24HoursTimeString(date: endTime)
//                    }
//                    
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "yyyy-MM-dd"
//                    
//                    let currentDate = strServerTime.count > 0 ? Utilities().convertStringToDateFormat(dateString: strServerTime) : Utilities().convertStringToDateFormat(dateString: Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"))
//                    let currentDateString = dateFormatter.string(from: currentDate as Date)
//                    
//                    let currentDateNew = Utilities().toDate(dateString: currentDateString)
//                    let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
//                    
//                    let dateFormatter1 = DateFormatter()
//                    dateFormatter1.dateFormat = "HH:mm"
//                    let currentTimeString = dateFormatter1.string(from: currentDate as Date)
//                    print("current time in cell for row \(currentTimeString)")
//                    let combinedDateTimeString = "\(currentDateStringNew) \(currentTimeString)"
//                    
//                    /*
//                     if (startDate?.compare(currentDate!) == .orderedAscending || startDate?.compare(currentDate!) == .orderedSame) && currentDateStringNew <= endDateString {
//                     */
//                    
//                    let formatter = DateFormatter()
//                    formatter.dateFormat = "dd-MM-yyyy HH:mm"
//                    let stDate = startDateTimeString
//                   // let stDate = formatter.date(from: startDateString + " " + startTimeString)
//                    print("cell for row start date \(stDate)")
//                    let enDate = endDateTimeString
//                  //  let enDate = formatter.date(from: endDateString + " " + endTimeString)
//                    print("cell for row end date \(enDate)")
//                    var nowDate = formatter.date(from: currentDateStringNew + " " + currentTimeString)
//                    print("cell for row now date \(nowDate)")
//                    if strServerTime == ""
//                    {
//                        let snowDate = Utilities().localToUTC(date: currentDateStringNew + " " + currentTimeString, true)
//                        let ssDate = snowDate.components(separatedBy: " ")
//                        nowDate = formatter.date(from: ssDate[0] + " " + ssDate[1])
//                    }
//                    
//                   // if startDateTimeString <= combinedDateTimeString && endDateTimeString >= combinedDateTimeString
//                    if (stDate.compare(combinedDateTimeString) == .orderedAscending || stDate.compare(combinedDateTimeString) == .orderedSame) && (enDate.compare(combinedDateTimeString) == .orderedDescending || enDate.compare(combinedDateTimeString) == .orderedSame)
//                    {
//                        cell?.contentView.backgroundColor = .clear
//                    }
//                    else
//                    {
//                        cell?.contentView.backgroundColor = .lightGray
//                    }
//                }
//                else {
//                    cell?.contentView.backgroundColor = .clear
//                }
//            }
//            
//            return cell!
//        } else {
//            return UITableViewCell()
//        }
//    }
/// ADDED CODE FOR TEST
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockListTableViewCell") as! LockListTableViewCell
            cell.selectionStyle = .none
            
            let lockListObj = lockListArray[indexPath.row]
            cell.lockNameLabel.text = lockListObj.lockname
            
            if lockListObj.lock_keys.count > 0 {
                let userObj = lockListObj.lock_keys[1] as! UserLockRoleDetails
                
                if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                    let startDate = Utilities().toDateT(dateString: userObj.schedule_date_from)!
                    print("start date for lock list = \(startDate)")
                    let endDate = Utilities().toDateT(dateString: userObj.schedule_date_to)!
                    print("end date for lock list = \(endDate)")
                    let startTime = Utilities().toTimeT(timeString: userObj.schedule_time_from)!
                    print("start time for lock list = \(startTime)")
                    var endTime = Utilities().toTimeT(timeString: userObj.schedule_time_to)!
                    print("end time for lock list = \(endTime)")
                    
                    let startDateTimeString = Utilities().toDateStringT(date: startDate) + " " + Utilities().toTimeStringT(time: startTime)
                    print("start date time for lock list = \(startDateTimeString)")
                    var endDateTimeString = Utilities().toDateStringT(date: endDate) + " " + Utilities().toTimeStringT(time: endTime)
                    print("end date time for lock list = \(endDateTimeString)")
                    if startTime > endTime {
                        endTime = Calendar.current.date(byAdding: .day, value: 1, to: endTime)!
                        endDateTimeString = Utilities().toDateStringT(date: endDate) + " " + Utilities().toTimeStringT(time: endTime)
                    }
                    
                    let currentDateTimeString = Utilities().currentDateTimeStringT()
                    print("current date time for lock list = \(currentDateTimeString)")
                    if startDateTimeString <= currentDateTimeString && endDateTimeString >= currentDateTimeString {
                        cell.contentView.backgroundColor = .clear
                    } else {
                        cell.contentView.backgroundColor = .lightGray
                    }
                } else {
                    cell.contentView.backgroundColor = .clear
                }
            }
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lockListArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 //UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let lockListObj = lockListArray[indexPath.row]
        
        if lockListObj.lock_keys.count > 0 {
            var userObj = UserLockRoleDetails(json: [:])
            userObj = lockListObj.lock_keys[1] as UserLockRoleDetails
            
            print("********\(String(describing: lockListObj.lock_keys[1].lock_id))")
            print("********\(String(describing: lockListObj.lockname))")
            
            
            if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                
                if Connectivity().isConnectedToInternet() {
                    // get server time
                    
                    self.getServerTimeInBlock(withSuccessionBlock: { (response) in
                        self.strServerTime = response
                        self.lockListTableView.reloadData()
                        self.checkForExpiryAndNavigatingToDetailPage(tableView, didSelectRowAt: indexPath)
                    }) { (error) in
                        print(error)
                    }
                } else {
                    let alert = UIAlertController(title:ALERT_TITLE, message: "Please connect to internet to access schedule lock.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                
            } else {
                // Direct navigation to detail screen
                self.gotoLockerDetailPage(index: indexPath.row)
            }
        }
    }
    
//    func checkForExpiryAndNavigatingToDetailPage(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
//    {
//         var timeExpired = Bool()
//        
//        let lockListObj = lockListArray[indexPath.row]
//        if lockListObj.lock_keys.count > 0 {
//            var userObj = UserLockRoleDetails(json: [:])
//            userObj = lockListObj.lock_keys[1] as UserLockRoleDetails
//            
//            if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
//                
//                
//                let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
//               // print("start Date for lock list Access \(startDate)")
//                let startDateString = Utilities().toDateString(date: startDate)
//                print("start Date string for lock list Access \(startDateString)")
//                
//                let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
//              //  print("end Date for lock list Access \(endDate)")
//                let endDateString = Utilities().toDateString(date: endDate)
//                print("end Date string for lock list Access \(endDateString)")
//
//                let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
//                let startTimeString = Utilities().to24HoursTimeString(date: startTime)
//                print("start time string for lock access \(startTimeString)")
//                
//                let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
//                let endTimeString = Utilities().to24HoursTimeString(date: endTime)
//                print("end time string for lock access \(endTimeString)")
//                
//                let startDateTimeString = "\(startDateString) \(startTimeString)"
//                print("start date time string \(startDateTimeString)")
//                let endDateTimeString = "\(endDateString) \(endTimeString)"
//                print("end date time string \(endDateTimeString)")
//                
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd"
//                
//                let serverTimeString = strServerTime
//                let dateTimeWithoutSeconds = String(serverTimeString.dropLast(3))
//                print("Date and Time without seconds: \(dateTimeWithoutSeconds)")
//                
//                let dateFormatter2 = DateFormatter()
//                dateFormatter2.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                 let serverDate = dateFormatter2.date(from: serverTimeString)
//                     let dateOnlyFormatter = DateFormatter()
//                    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
//                    let timeOnlyFormatter = DateFormatter()
//                    timeOnlyFormatter.dateFormat = "HH:mm:ss"
//                let dateString = dateOnlyFormatter.string(from: serverDate!)
//                let timeString = timeOnlyFormatter.string(from: serverDate!)
//                    print("Date: \(dateString)")  // Output: "Date: 2024-06-22"
//                    print("Time: \(timeString)")  // Output: "Time: 15:11:43"
//                let currentDate = strServerTime.count > 0 ? Utilities().convertStringToDateFormat(dateString: strServerTime) : Date()
//                let currentDateString = dateFormatter.string(from: currentDate as Date)
//                print("Current Date = \(currentDateString)")
//                let currentDateNew = Utilities().toDate(dateString: currentDateString)
//                let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
//                print("current date new \(currentDateStringNew)")
//                let dateFormatter1 = DateFormatter()
//                dateFormatter1.dateFormat = "HH:mm"
//                let currentTimeString = dateFormatter1.string(from: currentDate as Date)
//                print("server time = \(strServerTime)")
//                
//                let formatter = DateFormatter()
//                formatter.dateFormat = "dd-MM-yyyy HH:mm"
//                let stDate = startDateTimeString
//                //let stDate = formatter.date(from: startDateString + " " + startTimeString)
//                print("final start date \(stDate)")
//             //   let enDate = formatter.date(from: endDateString + " " + endTimeString)
//                let enDate = endDateTimeString
//                print("final end date \(enDate)")
//              //  let nowDate = formatter.date(from: currentDateStringNew + " " + currentTimeString)
//                let nowDate = dateTimeWithoutSeconds
//                print("final now date \(nowDate)")
//                //                if (stDate?.compare(nowDate!) == .orderedAscending || stDate?.compare(nowDate!) == .orderedSame) && (enDate?.compare(nowDate!) == .orderedDescending || enDate?.compare(nowDate) == .orderedSame)
//                if (stDate.compare(nowDate) == .orderedAscending || stDate.compare(nowDate) == .orderedSame) && (enDate.compare(nowDate) == .orderedDescending || enDate.compare(nowDate) == .orderedSame)
//                {
//                    timeExpired = false
//                    
//                }
//                else {
//                    timeExpired = true
//                    
//                }
//                
//            } else {
//                timeExpired = false
//            }
//            
//            
//            if !timeExpired && Connectivity().isConnectedToInternet(){
//                gotoLockerDetailPage(index: indexPath.row)
//            } else {
//                
//                var message = ""
//                
//                if Connectivity().isConnectedToInternet()
//                {
//                    message = "You don't have permission to access now"
//                }
//                else
//                {
//                    if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue
//                    {
//                        message = "Please connect to internet to access schedule lock."
//                    }
//                    else
//                    {
//                        gotoLockerDetailPage(index: indexPath.row)
//                        return
//                    }
//                }
//                
//                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                }))
//                self.present(alert, animated: true, completion: nil)
//            }
//        }
//        
//    }
    
/// ADDED CODE FOR TESTING
    
    func checkForExpiryAndNavigatingToDetailPage(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var timeExpired = false
        
        let lockListObj = lockListArray[indexPath.row]
        if lockListObj.lock_keys.count > 0 {
            let userObj = lockListObj.lock_keys[1] as! UserLockRoleDetails
            
            if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                let startDate = Utilities().toDateT(dateString: userObj.schedule_date_from)!
                print("start date for expiry \(startDate)")
                let endDate = Utilities().toDateT(dateString: userObj.schedule_date_to)!
                print("end date for expiry \(endDate)")
                let startTime = Utilities().toTimeT(timeString: userObj.schedule_time_from)!
                print("start time for expiry \(startTime)")
                let endTime = Utilities().toTimeT(timeString: userObj.schedule_time_to)!
                print("end time for expiry \(endTime)")
                let startDateTime = Utilities().toDateStringT(date: startDate) + " " + Utilities().toTimeStringT(time: startTime)
                print("start date time for expiry \(startDateTime)")
                let endDateTime = Utilities().toDateStringT(date: endDate) + " " + Utilities().toTimeStringT(time: endTime)
                print("end date time for expiry \(endDateTime)")
                let currentDateTime = Utilities().currentDateTimeStringT()
                print("current date time for expiry \(currentDateTime)")
                
                if (startDateTime <= currentDateTime && endDateTime >= currentDateTime) {
                    timeExpired = false
                } else {
                    timeExpired = true
                }
            } else {
                timeExpired = false
            }
            
            if !timeExpired && Connectivity().isConnectedToInternet() {
                gotoLockerDetailPage(index: indexPath.row)
            } else {
                var message = ""
                
                if Connectivity().isConnectedToInternet() {
                    message = "You don't have permission to access now"
                } else {
                    if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                        message = "Please connect to internet to access schedule lock."
                    } else {
                        gotoLockerDetailPage(index: indexPath.row)
                        return
                    }
                }
                
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /*
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
     if self.strServerTime == ""
     {
     self.getServerTimeInBlock(withSuccessionBlock: { (response) in
     self.strServerTime = response
     self.lockListTableView.reloadData()
     self.navigatingToDetailPage(tableView, didSelectRowAt: indexPath)
     }) { (error) in
     print(error)
     }
     }
     else
     {
     self.navigatingToDetailPage(tableView, didSelectRowAt: indexPath)
     }
     }*/
    
    func navigatingToDetailPage(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // navigate to lock details
        
        var timeExpired = Bool()
        
        let lockListObj = lockListArray[indexPath.row]
        if lockListObj.lock_keys.count > 0 {
            var userObj = UserLockRoleDetails(json: [:])
            userObj = lockListObj.lock_keys[1] as UserLockRoleDetails
            
            if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue {
                
                
                let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
                let startDateString = Utilities().toDateString(date: startDate)
                
                let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
                let endDateString = Utilities().toDateString(date: endDate)
                
                let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                
                let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                //            let currentDate = NSDate()
                let currentDate = strServerTime.count > 0 ? Utilities().convertStringToDateFormat(dateString: strServerTime) : Date()
                
                let currentDateString = dateFormatter.string(from: currentDate as Date)
                
                let currentDateNew = Utilities().toDate(dateString: currentDateString)
                let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                
                let dateFormatter1 = DateFormatter()
                dateFormatter1.dateFormat = "HH:mm"
                let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                /*
                 if currentDateNew == endDate {
                 if currentTimeString > endTimeString {
                 // expired
                 timeExpired = true
                 } else {
                 timeExpired = false
                 }
                 } else if currentDateNew > endDate {
                 // expired
                 timeExpired = true
                 
                 } else if startDate < currentDateNew && currentDateNew < endDate {
                 if startTimeString < currentTimeString && currentTimeString < endTimeString {
                 timeExpired = false
                 } else {
                 timeExpired = true
                 }
                 } else {
                 timeExpired = true
                 }
                 */
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd-MM-yyyy HH:mm"
                let stDate = formatter.date(from: startDateString + " " + startTimeString)
                let enDate = formatter.date(from: endDateString + " " + endTimeString)
                let nowDate = formatter.date(from: currentDateStringNew + " " + currentTimeString)
                
                if (stDate?.compare(nowDate!) == .orderedAscending || stDate?.compare(nowDate!) == .orderedSame) && (enDate?.compare(nowDate!) == .orderedDescending || enDate?.compare(nowDate!) == .orderedSame)
                {
                    timeExpired = false
                }
                else {
                    timeExpired = true
                }
                
            } else {
                timeExpired = false
            }
            
            if !timeExpired && Connectivity().isConnectedToInternet(){
                gotoLockerDetailPage(index: indexPath.row)
            } else {
                
                var message = ""
                
                if Connectivity().isConnectedToInternet()
                {
                    message = "You don't have permission to access now"
                }
                else
                {
                    if userObj.is_schedule_access == "1" && userObj.user_type.lowercased() != UserRoles.owner.rawValue
                    {
                        message = "Please connect to internet to access schedule lock."
                    }
                    else
                    {
                        gotoLockerDetailPage(index: indexPath.row)
                        return
                    }
                }
                
                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func gotoLockerDetailPage(index: Int)
    {
        BLELockAccessManager.shared.delegate = nil
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let lockDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "LockDetailsViewController") as! LockDetailsViewController
        
        lockDetailsViewController.lockListDetailsObj = lockListArray[index]
        
        //        //print("lockListArray[indexPath.row] ==> ")
        //        //print(lockListArray[indexPath.row])
        
        let advertisementData = BLELockAccessManager.shared.scanController.matchingPeripheral("", lockDetailsViewController.lockListDetailsObj.serial_number)
        lockDetailsViewController.lockConnection.selectedLock = advertisementData
        lockDetailsViewController.lockConnection.serialNumber = lockDetailsViewController.lockListDetailsObj.serial_number
        print("locks serial number = \(String(describing: lockDetailsViewController.lockListDetailsObj.serial_number))")
        print("locks passagemode = \(String(describing: lockDetailsViewController.lockListDetailsObj.enable_passage))")
        UserController.sharedController.loadDataOffline(forSerialNumber: lockDetailsViewController.lockConnection.serialNumber)
        self.navigationController?.pushViewController(lockDetailsViewController, animated: true)
        
    }
}

// MARK: - UITextFieldDelegate

extension LockListViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.lockDeviceTextField{
            self.lockDeviceTextField.text = "Select Lock"
            self.selectLockFromBLEOrWifi()
            return false
        }
        return true
    }
    
    /*
     func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     if string.rangeOfCharacter(from: NSCharacterSet.letters) != nil {
     return true
     } else {
     return false
     }
     }
     */
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.disableLockButton()
        if textField == self.lockCodeTextField {
            triedBLEDeviceList = []
            if string.rangeOfCharacter(from: NSCharacterSet.alphanumerics) != nil && (textField.text?.count)! < JsonUtils().getScratchCodeLength() {
                return true
                
            } else if string == "" {
                //print("Backspace pressed")
                return true
                
            } else {
                return false
            }
        } else if textField == self.lockNameTextField {
            if (string.rangeOfCharacter(from: NSCharacterSet.letters) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) ||  (string.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil) && (textField.text?.count)! < 50    {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                return true
            } else if string == "" {
                //print("Backspace pressed")
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

extension LockListViewController : BLELockAccessManagerDelegate {
    func didPeripheralDisconnect() {
        isAddButtonTapped = false
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            // Utilities.showErrorAlertView(message: "Device Disconnected", presenter: self)
            
            //print("didPeripheralDisconnect ==> called")
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self)
        }
        
        //print("isReadAllKeys ==> ")
        //print(isReadAllKeys)
        
        if !isReadAllKeys && !isActivationFailed {
            Utilities.showErrorAlertView(message: "Failed to fetch data from the lock. Please try again", presenter: self)
        }
        
    }
    
    func didCompleteReadingOwnerId() {
        
        //print("didCompleteReadingOwnerId")
        
    }
    
    func didFailReadingOwnerId() {
        //print("didFailReadingOwnerId")
        lockActivationFailed()
    }
    
    func didCompleteReadingAllTheKeys() {
        
        //print("didCompleteReadingAllTheKeys")
        
        isReadAllKeys = true
        
    }
    
    func didFailReadingAllTheKeys() {
        //print("didFailReadingAllTheKeys")
        lockActivationFailed()
    }
    
    func didDisactivateLock() {
        //print("didDisactivateLock")
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.lockConnection.hardwareData = BLELockAccessManager.shared.lockHardwareData
            
            if Connectivity().isConnectedToInternet() {
                self.addLockDetailsServiceCall()
            } else {
                self.saveLockLocalAddedViaBLE(lockHardwareData: self.lockConnection.hardwareData!)
            }
        }
        BLELockAccessManager.shared.disconnectLock()
    }
    
    func didFailDisactivation() {
        
        //print("didFailDisactivation")
        lockActivationFailed()
        processAddLock()
    }
    
    
    func didFailedToConnect(error: String) {
        isAddButtonTapped = false
        //print("didFailedToConnect")
    }
    
    func didFinishReadingAllCharacteristics() {
        //print("didFailedToConnect")
        let lockCode = self.getScartchCode()
        if lockCode != nil && !lockCode.isEmpty{
            BLELockAccessManager.shared.activateLock(scratchCode: lockCode )
        }
        else{
            //print("different from activate sequence ")
        }
    }
    func didActivateLock(isSuccess: Bool, error: String) {
        isAddButtonTapped = false
        //        //print(<#T##items: Any...##Any#>)
        
        // BLE failed to connect
        if isSuccess == false {
            
            isActivationFailed = true
            
            /*
             if availableListOfLockCount == recentlyProcessedLockIndex+1 {
             // connect to wifi
             let message = SETTINGS_NAVIGATION
             let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
             /*
              alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
              
              }))*/
             alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
             //self.navigateToDeviceSettings()
             }))
             self.present(alert, animated: true, completion: nil)
             
             } else {
             self.connectDeviceToBLE()
             }
             */
            
            var errorMessage = ""
            
            if error != "Encryption is insufficient." {
                
                if !triedBLEDeviceList.contains(availableListOfLock[0].formattedLocalName) {
                    triedBLEDeviceList.append(availableListOfLock[0].formattedLocalName)
                }
            }
            
            if error == "Authorization is insufficient." {
                errorMessage = "Lock already added and activated"
            }
            if error == "Encryption is insufficient." {
                errorMessage = "Unable to add the lock. Please try again"
            }
            DispatchQueue.main.async {
                Utilities.showErrorAlertView(message: errorMessage, presenter: self)
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
            
            self.isConnectedToBLE = false
        } else {
            isActivationFailed = false
            self.isAddLockScanning = false
            //print("didActivateLock ==> lock activated ==> ")
            self.isConnectedToBLE = true
        }
    }
}
extension LockListViewController
{
    func selectLockFromBLEOrWifi(){
        lockConnection = LockConnection()
        self.view.endEditing(true)
        if lockConnection.isConnectedToLockWifi() == true{
            let ssid  = lockConnection.ssid
            LoaderView.sharedInstance.showShadowView(title: "Connecting by Wifi", selfObject: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // your code here
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
            }
            self.lockDeviceTextField.text = ssid!
            self.lockConnection.isConnectedByBLE = false
            self.lockConnection.ssid = ssid
            
        }
        else {
            self.showPickerView()
        }
    }
    func showPickerView(){
        let access = BLELockAccessManager.shared.checkForBluetoothAccess()
        if access.canAccess == true {
            let scanPeripheralController = ScanPeripheralViewController(nibName: "ScanPeripheralViewController", bundle: nil)
            scanPeripheralController.closeHandler = {[weak self] selectedLock in
                guard let self = self else { return }
                //print("selectedLock ==> lock list ==>  ")
                //print(selectedLock)
                if let _ = selectedLock{
                    self.lockConnection.selectedLock = selectedLock
                    
                    //print("self.lockConnection.selectedLock ==> lock list closure ==> ")
                    //print(self.lockConnection.selectedLock)
                    
                    
                    self.lockConnection.selectedLock?.peripheral = selectedLock?.peripheral
                    
                    //print("self.lockConnection.selectedLock?.peripheral ==> lock list ====")
                    
                    //print(self.lockConnection.selectedLock?.peripheral ?? "")
                    
                    self.lockConnection.isConnectedByBLE = true
                    DispatchQueue.main.async {
                        self.lockDeviceTextField.text = self.lockConnection.selectedLock?.formattedLocalName
                        
                    }
                }
                scanPeripheralController.dismiss(animated: true, completion: nil)
                //print("self.lockConnection.selectedLock ==> lock after dismiss ==> ")
                //                //print(self.lockConnection.selectedLock)
                
            }
            self.present(scanPeripheralController, animated: true, completion: nil)
        }
        else{
            checkForBLEAccess()
        }
        
    }
    
    func lockActivationFailed(){
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            Utilities.showErrorAlertView(message: "Lock not added", presenter: self)
            LoaderView.sharedInstance.hideShadowView(selfObject: self)
            BLELockAccessManager.shared.disconnectLock()
        }
    }
}

extension LockListViewController:BLELockScanControllerProtocol{
    func didEndScan() {
        //print("didEndScan ==> ==> ")
        
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        
        if availableListOfLock.count > 0 {
            
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            isAddButtonTapped = false
            Utilities.showErrorAlertView(message: "Lock connection TimedOut", presenter: self)
        }
    }
    
    func didDiscoverNewLock(devices: [BluetoothAdvertismentData]) {
        //print("didDiscoverNewLock ==>")
        //print(devices)
        availableListOfLock = devices
        
        self.addLockViaBLE()
    }
    
    func initializeScan(){
        let scanController = BLELockAccessManager.shared.scanController
        scanController.scanDelegate = self
        scanController.prolongedScanForPeripherals()//scanForPeripherals()
        availableListOfLock.append(contentsOf: scanController.scannedDevicesList)
        
        //print(availableListOfLock)
    }
    
}

extension LockListViewController {
    
    @objc func handlePassageModeChange(_ notification: Notification) {
        guard let lockId = notification.userInfo?["lockId"] as? String,
              let isEnabled = notification.userInfo?["isEnabled"] as? Bool,
              let index = lockListArray.firstIndex(where: { $0.id == lockId }) else {
            return
        }
        print("Passage mode for lock \(lockId) is now \(isEnabled ? "enabled" : "disabled")")
        lockListArray[index].enable_passage = isEnabled ? "1" : "0"
        print("enable_passage is \(String(describing: lockListArray[index].enable_passage))")
        lockListTableView.reloadData()
    }
    
    func checkForceUpdate() {
        setRemoteConfig()
        remoteConfig.fetch { (status, error) -> Void in
            if status == .success {
                
                self.remoteConfig.activate()
                
            } else {
                
            }
            
            let version = self.remoteConfig["ios_version_code"].numberValue
            
            let appVersion =  Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0")
            
            print("version : \(version)");
            print("version : \(appVersion)");
            
            let isForceUpdateFlag = self.remoteConfig["ios_force_update"].boolValue
            
            self.message = self.remoteConfig["ios_force_update_message"].stringValue ?? ""
            
            
            if let lastAppVersion = appVersion {
                
                if isForceUpdateFlag && (lastAppVersion<Int(truncating: version)) {
                    self.updatePriority = .high
                    self.updateAlert()
                }
                else if !isForceUpdateFlag && (lastAppVersion<Int(truncating: version)) {
                    self.updatePriority = .medium
                    self.updateAlert()
                }
                else {
                }
            }
        }
    }
    
    func setRemoteConfig(){
        
        remoteConfig = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        
        settings.minimumFetchInterval = 0
        
        remoteConfig.configSettings = settings
        
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    func updateAlert() {
        
        let updateAlert = UIAlertController(title: "Update Available", message: message, preferredStyle: .alert)
        
        
        let laterAction = UIAlertAction(title: "Later", style: .default) { (action) in
        }
        
        let appStoreUrl = Bundle.main.object(forInfoDictionaryKey: "AppStoreUrl") as! String
        
        let updateAction = UIAlertAction(title: "Upgrade", style: .default) { (action) in
            if let url = URL(string: appStoreUrl), !url.absoluteString.isEmpty {
                
                self.updateAlert()
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                
                self.updateAlert()
                
            }
        }
        switch updatePriority {
            case .high?:
                updateAlert.addAction(updateAction)
                break
            case .medium?:
                updateAlert.addAction(laterAction)
                updateAlert.addAction(updateAction)
                break
            default:
                return
        }
        
        self.present(updateAlert, animated: true, completion: nil)
        
    }
    
    func getScartchCode()-> String{
        var droppedString = self.lockCodeTextField.text ?? ""
        if JsonUtils().getScratchCodePrefix().count == 0{
            if self.lockCodeTextField.text?.count == Int(JsonUtils().getScratchCodeLength()) {
                droppedString = String(self.lockCodeTextField.text?.dropFirst(1) ?? "")
                
            }
        } else {
            droppedString = String(self.lockCodeTextField.text?.dropFirst(JsonUtils().getScratchCodePrefix().count) ?? "")
        }
        //        if self.lockCodeTextField.text?.count == 9 {
        //            scartchString.remove(at: scartchString.startIndex)
        //        }
        return droppedString
    }
    func getAppConfiguration(){
        //      let urlString =  "https://smartlock.payoda.com/api/web/v1/versions/configlist"
        let urlString = ServiceUrl.BASE_URL + ServerUrl.versionConfiguration.rawValue
        print(" = \(urlString)")
        NetworkManager().getServerDateAndTimeServiceCall(url: urlString, userDetails: [:]) { (response, error) in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if let error = error {
                print("Error during network request: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                print("No response from the server.")
                return
            }
            
            //            if response != nil
            //            {
            if let jsonString = response["data"].rawString() {
                UserDefaults.standard.setValue(jsonString, forKey: UserdefaultsKeys.versionConfiguration.rawValue)
                print("JsonString = \(jsonString)")
            } else {
                print("Unable to extract 'data' field from the server response.")
            }
            // }
        }
    }
}

enum Priority {
    case high
    case medium
}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
