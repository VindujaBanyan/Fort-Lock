//
//  EditScheduleAccessViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 27/11/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class EditScheduleAccessViewController: UIViewController {
    
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var endTimeTextField: UITextField!
    
    var customSaveBtnItem = UIBarButtonItem()
    var customDoneBtnItem = UIBarButtonItem()

    let startDatePicker = UIDatePicker()
    let endDatePicker = UIDatePicker()
    let startTimePicker = UIDatePicker()
    let endTimePicker = UIDatePicker()
    
    var isEditSchedule = Bool()
    var keyID = String()
    var userObj = AssignUserModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    // MARK: - Initialize methods
    
    func initialize() {
        title = "Schedule"
        addBackBarButton()
        addRightBarButton()
        setStartDatePickerAsInputView()
        setEndDatePickerAsInputView()
        setStartTimeDatePickerAsInputView()
        setEndTimeDatePickerAsInputView()
        if isEditSchedule {
            setTextFieldValues()
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
    
    func addRightBarButton() {
        let saveBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        saveBtn.addTarget(self, action: #selector(self.onTapSaveButton), for: UIControl.Event.touchUpInside)
        saveBtn.setTitle("Save", for: .normal)
        
        saveBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        saveBtn.sizeToFit()
        customSaveBtnItem = UIBarButtonItem(customView: saveBtn)
        
        let doneBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        doneBtn.addTarget(self, action: #selector(self.onTapDoneButton), for: UIControl.Event.touchUpInside)
        doneBtn.setTitle("Done", for: .normal)
        
        doneBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        doneBtn.sizeToFit()
        customDoneBtnItem = UIBarButtonItem(customView: doneBtn)
        self.navigationItem.rightBarButtonItem = self.customSaveBtnItem
    }
    
    // MARK: - Navigation BarButton Actions
    
    @objc func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
    
    @objc func onTapSaveButton() {
        
        onDateSelectionCancel()
        if (startDateTextField.text?.isEmpty)! {
            showAlertWithMessage(message: START_DATE_MANDATORY)
        } else if (endDateTextField.text?.isEmpty)! {
            showAlertWithMessage(message: END_DATE_MANDATORY)
        } else if (startTimeTextField.text?.isEmpty)! {
            showAlertWithMessage(message: START_DATE_MANDATORY)
        } else if (endTimeTextField.text?.isEmpty)! {
            showAlertWithMessage(message: END_TIME_MANDATORY)
        } else if !isValidEndDate() {
            showAlertWithMessage(message: VALID_END_DATE)
        } else if !isEndTimeGreaterThanStartTime() {
            showAlertWithMessage(message: VALID_END_TIME)
        } else if !isValidEndTime() {
            showAlertWithMessage(message: VALID_END_TIME)
        } else {
            createOrUpdateScheduleAccessServiceCall(keyID: keyID)
        }
    }
    
    @objc func onTapDoneButton() {
        
    }
    
    // MARK: - Set TextField Value methods
    
    func setTextFieldValues() {
        
        let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
        let startDateString = Utilities().toDateString(date: startDate)
        
        let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
        let endDateString = Utilities().toDateString(date: endDate)
        
        let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
        let startTimeString = Utilities().toTimeString(date: startTime)
        
        let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
        let endTimeString = Utilities().toTimeString(date: endTime)
        
        startDatePicker.date = startDate
        endDatePicker.date = endDate
        startTimePicker.date = startTime
        endTimePicker.date = endTime
        
        startDateTextField.text = startDateString
        endDateTextField.text = endDateString
        startTimeTextField.text = startTimeString
        endTimeTextField.text = endTimeString
    }
    
    // MARK: - Validation Methods
    
    func isValidEndDate() -> Bool {
        
        if startDatePicker.date <= endDatePicker.date {
            return true
        }
        return false
    }
    
    func isEndTimeGreaterThanStartTime() -> Bool {
        
        if startTimePicker.date < endTimePicker.date {
            return true
        }
        return false
    }
    
    func isValidEndTime() -> Bool {
        // start & end date same
        // check current date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy" // hh:mm a
        let startDate = dateFormatter.string(from: startDatePicker.date)
        let endDate = dateFormatter.string(from: endDatePicker.date)

        //print("startDate ==> ===========> \(startDate)")
        //print("endDate ==> ===========> \(endDate)")
        
        let currentDate = NSDate().addingTimeInterval(300)
        
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "HH:mm" // hh:mm a
        let currentTime = dateFormatter1.string(from: currentDate as Date)
        let endTime = dateFormatter1.string(from: endTimePicker.date)
        let startTime = dateFormatter1.string(from: startTimePicker.date)
        
        //print("NSDate()  time ==> \(currentTime)")
        //print("endTime ==> \(endTime)")
        
        if startDate == endDate {
            // check for current time
            
            //print("NSDate() ==> \(NSDate())")
            //print("endTimePicker.date ==> \(endTimePicker.date)")
            
            if currentTime < endTime {
                return true
            }
        } else {
            
        }
        
        if startTime < endTime {
            return true
        }
        
        return false
    }
    
    // MARK: - Alert
    
    func showAlertWithMessage(message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Service Call
    
    func createOrUpdateScheduleAccessServiceCall(keyID: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "keys/updateschedule?key_id=\(keyID)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: startDatePicker.date)
        let endDate = dateFormatter.string(from: endDatePicker.date)

        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "HH:mm:ss"
        let startTime = dateFormatter1.string(from: startTimePicker.date)
        let endTime = dateFormatter1.string(from: endTimePicker.date)
        print(startDate + " " + startTime)
        print(endDate + " " + endTime)
        let startDateUTC = Utilities().localToUTC(date: startDate + " " + startTime)
        let endDateUTC = Utilities().localToUTC(date: endDate + " " + endTime)
        print(startDateUTC)
        print(endDateUTC)

        
        let arrStartDateTime = startDateUTC.components(separatedBy: " ")
        let arrEndDateTime = endDateUTC.components(separatedBy: " ")
        /*
         /api/web/v1/keys/updateschedule?key_id=1623

         {
         "is_schedule_access" : 1,
         "schedule_date_from" : "2018-11-15",
         "schedule_date_to" :  "2018-11-15",
         "schedule_time_from" : "12:52:50",
         "schedule_time_to" : "12:52:51"
         }

 */
        let userDetailsDict = [
            "is_schedule_access": 1,
            "schedule_date_from" : arrStartDateTime[0],
            "schedule_date_to" :  arrEndDateTime[0],
            "schedule_time_from" : arrStartDateTime[1],
            "schedule_time_to" : arrEndDateTime[1]
            ] as [String : Any]
        
        var userDetails = [String: Any]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            if let dictFromJSON = decoded as? [String: Any] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        AssignUsersViewModel().createOrUpdateScheduleAccessServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                var message = SCHEDULED_ACCESS_SUCCESS_MESSAGE
                if self.isEditSchedule {
                    message = SCHEDULED_ACCESS_UPDATE_MESSAGE
                }
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    for controller in self.navigationController!.viewControllers as Array {
                        if controller.isKind(of: AssignUsersViewController.self) {
                            _ =  self.navigationController!.popToViewController(controller, animated: true)
                            break
                        }
                    }
                }))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showAlertWithMessage(message: message)
            }
        }
    }
    
}

// MARK: - Custom Date picker

extension EditScheduleAccessViewController {
    
    func setStartDatePickerAsInputView() {
        
        let inputView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 263 - 44, width: UIScreen.main.bounds.size.width, height: 260))
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        
        let currentDate = NSDate()
        _ = currentDate.addingTimeInterval(1800)
        
        startDatePicker.minimumDate = NSDate() as Date
        startDatePicker.frame = CGRect(x: 0, y: 44, width: UIScreen.main.bounds.size.width, height: 216)
        startDatePicker.datePickerMode = .date
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onStartDateSelectionComplete))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.onDateSelectionCancel))
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        doneButton.tintColor = .red
        cancelButton.tintColor = .red
        
        toolbar.items = [cancelButton, flexibleButton, doneButton]
        
        inputView.addSubview(toolbar)
        inputView.addSubview(startDatePicker)
        
        startDateTextField.inputView = inputView
    }
    
    func setEndDatePickerAsInputView() {
        
        let inputView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 263 - 44, width: UIScreen.main.bounds.size.width, height: 260))
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        
        let currentDate = NSDate()
        _ = currentDate.addingTimeInterval(1800)
        
        endDatePicker.minimumDate = NSDate() as Date
        endDatePicker.frame = CGRect(x: 0, y: 44, width: UIScreen.main.bounds.size.width, height: 216)
        endDatePicker.datePickerMode = .date
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onEndDateSelectionComplete))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.onDateSelectionCancel))
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        doneButton.tintColor = .red
        cancelButton.tintColor = .red
        
        toolbar.items = [cancelButton, flexibleButton, doneButton]
        
        inputView.addSubview(toolbar)
        inputView.addSubview(endDatePicker)
        
        endDateTextField.inputView = inputView
    }
    
    func setStartTimeDatePickerAsInputView() {
        
        let inputView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 263 - 44, width: UIScreen.main.bounds.size.width, height: 260))
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        
        let currentDate = NSDate()
        _ = currentDate.addingTimeInterval(1800)
        
        startTimePicker.frame = CGRect(x: 0, y: 44, width: UIScreen.main.bounds.size.width, height: 216)
        startTimePicker.datePickerMode = .time
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onStartTimeSelectionComplete))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.onDateSelectionCancel))
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        doneButton.tintColor = .red
        cancelButton.tintColor = .red
        
        toolbar.items = [cancelButton, flexibleButton, doneButton]
        
        inputView.addSubview(toolbar)
        inputView.addSubview(startTimePicker)
        
        startTimeTextField.inputView = inputView
    }
    
    func setEndTimeDatePickerAsInputView() {
        
        let inputView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 263 - 44, width: UIScreen.main.bounds.size.width, height: 260))
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        
        let currentDate = NSDate()
        _ = currentDate.addingTimeInterval(1800)
        
        endTimePicker.frame = CGRect(x: 0, y: 44, width: UIScreen.main.bounds.size.width, height: 216)
        endTimePicker.datePickerMode = .time
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onEndTimeSelectionComplete))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.onDateSelectionCancel))
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        doneButton.tintColor = .red
        cancelButton.tintColor = .red
        
        toolbar.items = [cancelButton, flexibleButton, doneButton]
        
        inputView.addSubview(toolbar)
        inputView.addSubview(endTimePicker)
        
        endTimeTextField.inputView = inputView
    }
    
    // MARK: - Custom Date Picker Button Actions
    
    @objc func onStartDateSelectionComplete() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy" // hh:mm a
        let selectedDate = dateFormatter.string(from: startDatePicker.date)
        startDateTextField.text = selectedDate
        startDateTextField.resignFirstResponder()
    }
    
    @objc func onEndDateSelectionComplete() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy" // hh:mm a
        let selectedDate = dateFormatter.string(from: endDatePicker.date)
        endDateTextField.text = selectedDate
        endDateTextField.resignFirstResponder()
    }
    
    @objc func onStartTimeSelectionComplete() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a" // hh:mm a
        let selectedDate = dateFormatter.string(from: startTimePicker.date)
        startTimeTextField.text = selectedDate
        startTimeTextField.resignFirstResponder()
    }
    
    @objc func onEndTimeSelectionComplete() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a" //
        let selectedDate = dateFormatter.string(from: endTimePicker.date)
        endTimeTextField.text = selectedDate
        endTimeTextField.resignFirstResponder()
    }
    
    @objc func onDateSelectionCancel() {
        startDateTextField.resignFirstResponder()
        endDateTextField.resignFirstResponder()
        startTimeTextField.resignFirstResponder()
        endTimeTextField.resignFirstResponder()
    }

}
