//
//  ScheduledAccessViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 19/11/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class ScheduledAccessViewController: UIViewController {
    
    @IBOutlet weak var scheduledAccessTableView: UITableView?
    
    var customEditBtnItem = UIBarButtonItem()

    var userObj = AssignUserModel()
    var userRole = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
//        scheduledAccessTableView?.backgroundColor = UIColor.white
        initialize()
    }
    
    // MARK: - Initialize methods

    func initialize() {
        title = "Scheduled Access"
        addBackBarButton()
        registerTableViewCell()
        scheduledAccessTableView?.separatorStyle = .none
        
        if userRole.lowercased() == UserRoles.owner.rawValue {
            switch userObj.slotNumber {
            case "01", "02", "03", "04", "05", "06", "07", "08":
                addEditBarButton()
            case "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23":
                break
            default:
                break
            }
        } else {
            addEditBarButton()
        }
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
    
    func addEditBarButton() {
        let editBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        editBtn.addTarget(self, action: #selector(self.onTapEditButton), for: UIControl.Event.touchUpInside)
        editBtn.setTitle("Edit", for: .normal)
        
        editBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        editBtn.sizeToFit()
        self.customEditBtnItem = UIBarButtonItem(customView: editBtn)
        self.navigationItem.rightBarButtonItem = self.customEditBtnItem
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        let nib = UINib.init(nibName: "ScheduledAccessViewTableViewCell", bundle: nil)
        scheduledAccessTableView!.register(nib, forCellReuseIdentifier: "ScheduledAccessViewTableViewCell")
    }
    
    // MARK: - Navigation BarButton Actions
    
    @objc func popToViewController() {
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func onTapEditButton() {
        if Connectivity().isConnectedToInternet() {

            navigateToEditScheduledAccessViewContorller(userObj: userObj)
            
        } else {
            let alert = UIAlertController(title: ALERT_TITLE, message: INTERNET_CONNECTION_VALIDATION, preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    // MARK: - NAvigation Methods
    
    func navigateToEditScheduledAccessViewContorller(userObj: AssignUserModel) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let scheduledAccessViewController = storyBoard.instantiateViewController(withIdentifier: "EditScheduleAccessViewController") as! EditScheduleAccessViewController
        scheduledAccessViewController.isEditSchedule = true
        scheduledAccessViewController.keyID = userObj.id
        scheduledAccessViewController.userObj = userObj
        self.navigationController?.pushViewController(scheduledAccessViewController, animated: true)
    }
}


extension ScheduledAccessViewController: UITableViewDataSource, UITableViewDelegate {
    
    
    // MARK： UITableViewDataSource
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.section == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledAccessViewTableViewCell", for: indexPath) as! ScheduledAccessViewTableViewCell
//            cell.selectionStyle = .none
//            
//            var detailText = ""
//            var imageName = ""
//            
//            switch indexPath.row {
//            case 0:
//                // Set start date
//                let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
//                    print("start date \(startDate)")
//                let startDateString = Utilities().toDateString(date: startDate)
//                    print("start date string \(startDateString)")
//                imageName = "scheduledAccessDate"
//                detailText = startDateString
//            case 1:
//                // Set end date
//                let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
//                let endDateString = Utilities().toDateString(date: endDate)
//                imageName = "scheduledAccessDate"
//                detailText = endDateString
//            case 2:
//                // Set start time
//                let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
//                    print("start Time \(startTime)")
//                    let startTimeString = Utilities().toTimeString(date: startTime)
//                    print("start Time string \(startTimeString)")
//                    detailText = startTimeString
//                    
//                    imageName = "scheduledAccessTime"
//            case 3:
//                // Set end time
//                let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
//                let endTimeString = Utilities().toTimeString(date: endTime)
//                    detailText = endTimeString
//                    imageName = "scheduledAccessTime"
//            default:
//                break
//            }
//            
//            cell.detailsLabel?.text = detailText
//            cell.iconImageView?.image = UIImage(named: imageName)
//            
//            return cell
//        } else {
//            return UITableViewCell()
//        }
//    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledAccessViewTableViewCell", for: indexPath) as! ScheduledAccessViewTableViewCell
            cell.selectionStyle = .none
            
            var detailText = ""
            var imageName = ""
            
            switch indexPath.row {
            case 0:
                // Set start date
//                let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
//                    print("start date \(startDate)")
//                let startDateString = Utilities().toDateString(date: startDate)
//                    print("start date string \(startDateString)")
                    let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
                    let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                    let combinedStartDateTime = EditScheduleAccessViewController().combineDateAndTime(date: startDate, time: startTime)
                    let startDateTimeUTCString = EditScheduleAccessViewController().convertDatePickerToUTC(date: combinedStartDateTime)
                    let startDateTimeUTC = Utilities().toDate(withFormat: "yyyy-MM-dd HH:mm:ss", dateString: startDateTimeUTCString)
                    let startDateUTCstring = Utilities().toDateString(date: startDateTimeUTC)
                    print("start date  utc String \(startDateUTCstring)")
                imageName = "scheduledAccessDate"
                detailText = startDateUTCstring
            case 1:
                // Set end date
//                let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
//                let endDateString = Utilities().toDateString(date: endDate)
//                    print("end date string \(endDateString)")
                    let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
                    let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                    let combinedEndDateTime = EditScheduleAccessViewController().combineDateAndTime(date: endDate, time: endTime)
                    
                    let endDateTimeUTCString = EditScheduleAccessViewController().convertDatePickerToUTC(date: combinedEndDateTime)
                    let endDateTimeUTC = Utilities().toDate(withFormat: "yyyy-MM-dd HH:mm:ss", dateString: endDateTimeUTCString)
                    print("end date time utc string \(endDateTimeUTC)")
                    let endDateUTCString = Utilities().toDateString(date: endDateTimeUTC)
                    print("end date utc string \(endDateUTCString)")
                imageName = "scheduledAccessDate"
                detailText = endDateUTCString
            case 2:
                // Set start time
                    let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
                    let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                    let combinedStartDateTime = EditScheduleAccessViewController().combineDateAndTime(date: startDate, time: startTime)
                    let startDateTimeUTCString = EditScheduleAccessViewController().convertDatePickerToUTC(date: combinedStartDateTime)
                    let startDateTimeUTC = Utilities().toDate(withFormat: "yyyy-MM-dd HH:mm:ss", dateString: startDateTimeUTCString)
                    let startTimeUTCString = Utilities().toTimeString(date: startDateTimeUTC)
                     detailText = startTimeUTCString
                     imageName = "scheduledAccessTime"
            case 3:
                // Set end time
                    let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
                    let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                    let combinedEndDateTime = EditScheduleAccessViewController().combineDateAndTime(date: endDate, time: endTime)
                    
                    let endDateTimeUTCString = EditScheduleAccessViewController().convertDatePickerToUTC(date: combinedEndDateTime)
                    let endDateTimeUTC = Utilities().toDate(withFormat: "yyyy-MM-dd HH:mm:ss", dateString: endDateTimeUTCString)
                    print("end date time utc string \(endDateTimeUTC)")
                    let endDateUTCString = Utilities().toDateStringT(date: endDateTimeUTC)
                   // print("end date utc string \(endDateUTCString)")
                    let endTimeUTCString = Utilities().toTimeString(date: endDateTimeUTC)
                    print("end time utc string \(endTimeUTCString)")
                    detailText = endTimeUTCString
                    imageName = "scheduledAccessTime"
            default:
                break
            }
            
            cell.detailsLabel?.text = detailText
            cell.iconImageView?.image = UIImage(named: imageName)
            
            return cell
        } else {
            return UITableViewCell()
        }
    }

/// ADDED CODE FOR TESTING
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.section == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledAccessViewTableViewCell", for: indexPath) as! ScheduledAccessViewTableViewCell
//            cell.selectionStyle = .none
//            
//            var detailText = ""
//            var imageName = ""
//            
//            switch indexPath.row {
//            case 0:
//                let startDate = Utilities().toDateT(dateString: userObj.schedule_date_from)
//                    let startDateString = Utilities().toDateStringT(date: startDate!)
//                imageName = "scheduledAccessDate"
//                detailText = startDateString
//            case 1:
//                    let endDate = Utilities().toDateT(dateString: userObj.schedule_date_to)
//                let endDateString = Utilities().toDateStringT(date: endDate!)
//                imageName = "scheduledAccessDate"
//                detailText = endDateString
//            case 2:
//                    let startTime = Utilities().toTimeT(timeString: userObj.schedule_time_from)
//                    let startTimeString = Utilities().toTimeStringT(time: startTime!)
//                imageName = "scheduledAccessTime"
//                detailText = startTimeString
//            case 3:
//                let endTime = Utilities().toTimeT(timeString: userObj.schedule_time_to)
//                let endTimeString = Utilities().toTimeStringT(time: endTime!)
//                imageName = "scheduledAccessTime"
//                detailText = endTimeString
//            default:
//                break
//            }
//            
//            cell.detailsLabel?.text = detailText
//            cell.iconImageView?.image = UIImage(named: imageName)
//            
//            return cell
//        } else {
//            return UITableViewCell()
//        }
//    }

    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if (indexPath as NSIndexPath).section == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledAccessViewTableViewCell") as? ScheduledAccessViewTableViewCell
//            cell?.selectionStyle = .none
//            
//            var detailText = ""
//            var imageName = ""
//            
//            switch(indexPath.row) {
//            case 0:
//                
//                let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
//                let startDateString = Utilities().toDateString(date: startDate)
//                imageName = "scheduledAccessDate"
//                detailText = startDateString
//            case 1:
//                
//                let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
//                let endDateString = Utilities().toDateString(date: endDate)
//                imageName = "scheduledAccessDate"
//                detailText = endDateString
//            case 2:
//                
//                let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
//                let startTimeString = Utilities().toTimeString(date: startTime)
//                imageName = "scheduledAccessTime"
//                detailText = startTimeString
//            case 3:
//                
//                let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
//                let endTimeString = Utilities().toTimeString(date: endTime)
//                imageName = "scheduledAccessTime"
//                detailText = endTimeString
//            default:
//                break
//            }
//            
//            cell?.detailsLabel?.text = detailText
//            cell?.iconImageView?.image = UIImage(named: imageName)
//            
//            return cell!
//        } else {
//            return UITableViewCell()
//        }
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 //UITableViewAutomaticDimension
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
