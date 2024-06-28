//
//  NotificationsViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 13/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import XLPagerTabStrip
class TablePagination{
    var limit = 20
    var offset = 0
//    var page = 1
    var shouldStopPaginate = false
    func paginationString() -> String {
        return "limit=\(limit)&offset=\(offset)"
    }
//    func paginationPageString() -> String {
//        return "limit=\(limit)&page=\(page)"
//    }

    func paginate(){
        if shouldStopPaginate == false {
        offset = offset + 1//limit
        }
    }
    
//    func paginateWithPage(){
//        if shouldStopPaginate == false {
//            page = page + 1
//        }
//    }

    func stopPaginate(){
        shouldStopPaginate = true
    }
}
class NotificationsViewController: UIViewController, IndicatorInfoProvider {

    @IBOutlet weak var noNotificationsView: UIView!
    @IBOutlet weak var notificationsTableView: UITableView!
    var itemInfo = IndicatorInfo(title: "Notification", image:  UIImage(named: "tab_notification"))
    
    var notificationListArray = [NotificationListModel]()
    let refresher = UIRefreshControl()
    var notificationPagination:TablePagination = TablePagination()
    var isFromRefresh = Bool()
    var isAllDataFetched = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
//        notificationsTableView.backgroundColor = UIColor.white

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationPagination.offset = 0
        isFromRefresh = true
        isAllDataFetched = false
        self.getNotificationListServiceCall()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - IndicatorInfoProvider
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        self.registerTableViewCell()
        self.addRefreshController()
//        self.mockData()
        self.notificationsTableView.reloadData()
        self.notificationsTableView.isHidden = true

        self.noNotificationsView.isHidden = false
    }
    
    //MARK: - Add refresh controller
    
    func addRefreshController() {
        self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.addTarget(self, action: #selector(self.refreshCall), for: .valueChanged)
        self.notificationsTableView!.addSubview(refresher)
    }
    
    @objc func refreshCall() {
        //print("refresh called")
        
        notificationPagination.offset = 0
        isFromRefresh = true
        isAllDataFetched = false
        self.getNotificationListServiceCall()
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        let nib1 = UINib.init(nibName: "NotificationTableViewCell", bundle: nil)
        self.notificationsTableView.register(nib1, forCellReuseIdentifier: "NotificationTableViewCell")
 
    }
    /*
    func mockData() {
        let obj1 = NotificationListModel()
        obj1.notificationTitle = "Payoda"
        obj1.notificationDate = ""
        obj1.notificationTime = "false"
        
        let obj2 = NotificationListModel()
        obj2.notificationTitle = "Payoda"
        obj2.notificationDate = "Accepted"
        obj2.notificationTime = "true"
        
        notificationListArray.append(obj1)
        notificationListArray.append(obj2)
    }
    
    */
    // MARK: - Service Call
    
    @objc func getNotificationListServiceCall() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

        let paginationString = notificationPagination.paginationString()
        if notificationPagination.shouldStopPaginate == true {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            notificationPagination.shouldStopPaginate = false
            notificationPagination.offset = 0
            return
        }

        let urlString = ServiceUrl.BASE_URL + "notifications/notificationlist?\(paginationString)"
        //print("notification list urlString ==> \(urlString)")
            NotificationViewModel().getNotificationListServiceViewModel(url: urlString, userDetails: [:], callback: { (result, error) in
                
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.refresher.endRefreshing()
                
//                //print("Result ==> \(String(describing: result ))")
                if result != nil {
                    // populate data from result and reload table
                    
                    if self.isFromRefresh {
                        self.isFromRefresh = false
                        self.notificationListArray.removeAll()
                        //print("isFromRefresh =============== >>>>>>>> \(self.notificationListArray.count)")
                        self.isAllDataFetched = false
                    }
                    
                    if result!.count < self.notificationPagination.limit {
                        self.isAllDataFetched = true
                        if self.notificationListArray.count > 0 {
                            self.noNotificationsView.isHidden = true
                            self.notificationsTableView.isHidden = false
                        } else {
                            self.noNotificationsView.isHidden = false
                            self.notificationsTableView.isHidden = true
                        }
                    }
                    
                    if let _notificationListArray = result {
                        self.notificationListArray.append(contentsOf: _notificationListArray)
                        DispatchQueue.main.async{[weak self] in
                            guard let self = self else { return }
                            if self.notificationListArray.count > 0 {
                                self.noNotificationsView.isHidden = true
                                self.notificationsTableView.isHidden = false
                            } else {
                                self.noNotificationsView.isHidden = false
                                self.notificationsTableView.isHidden = true
                            }

                            
//                            self.noNotificationsView.isHidden = true
//                            self.notificationsTableView.isHidden = false

//                            if self.notificationPagination.offset > 1 {
//                                if self.notificationListArray.count > 0 {
//                                    self.noNotificationsView.isHidden = true
//                                    self.notificationsTableView.isHidden = false
//                                } else {
//                                    self.noNotificationsView.isHidden = false
//                                    self.notificationsTableView.isHidden = true
//                                }
//                            }
                            self.notificationsTableView.reloadData()
                        }
                        if _notificationListArray.count < self.notificationPagination.limit{
                            self.notificationPagination.stopPaginate()
                        }
                    }
                    
                    /*
                    self.notificationListArray.removeAll()
                    self.notificationListArray = result!
                    if self.notificationListArray.count > 0 {
                        self.noNotificationsView.isHidden = true
                        self.notificationsTableView.isHidden = false
                    } else {
                        self.noNotificationsView.isHidden = false
                        self.notificationsTableView.isHidden = true
                    }
                    self.notificationsTableView.reloadData()
                    */
                    
                } else {
                    /*
                     let message = error?.userInfo["ErrorMessage"] as! String
                     let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                     
                     alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                     }))
                     self.present(alert, animated: true, completion: nil)
                     */
                }
            })
        
    }
}

// MARK: - UITableview

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // set delegate to tableviewcell
        
        let requestListObj = self.notificationListArray[indexPath.row] as NotificationListModel
        
        
        let cell = notificationsTableView.dequeueReusableCell(withIdentifier: "NotificationTableViewCell") as? NotificationTableViewCell
        cell?.selectionStyle = .none
//        cell?.backgroundColor = UIColor.white
        let notificationObj = notificationListArray[indexPath.row]
        
        cell?.notificationDetailLabel.text = notificationObj.notificationMessage // "Notification msg"
//        cell?.notificationDateTimeLabel.text = Utilities().convertDateAndTimeFormatter(notificationObj.notificationCreatedDateAndTime)  //"created date & time"
//        cell?.notificationDateTimeLabel.text = Utilities().convertDateTimeFromUTC(notificationObj.notificationCreatedDateAndTime)   //"created date & time"

        cell?.notificationDateTimeLabel.text = notificationObj.notificationCreatedDateAndTime//Utilities().UTCToLocal(date: notificationObj.notificationCreatedDateAndTime)   //"created date & time"

        
        return cell!
            
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notificationListArray.count
        
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
        
//        notificationPagination.paginate()
//        getNotificationListServiceCall()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.notificationListArray.count - 1 == indexPath.row {
            if !isAllDataFetched && !isFromRefresh {
                notificationPagination.paginate()
                getNotificationListServiceCall()
            } else {
                
            }
        }
    }

    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // navigate to lock details
        
    }
}
