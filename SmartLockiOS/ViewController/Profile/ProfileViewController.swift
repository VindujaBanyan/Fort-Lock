//
//  ProfileViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 01/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import SKCountryPicker

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var appVersionLabel: UILabel!
    
    @IBOutlet weak var profileTableView: UITableView!
    
    var listPlaceholserData = ["Name", "Email", "Mobile", "Address", "Access granted time"]
    var listData = ["","","","",""]//["Payoda", "payoda@gmail.com", "9334567890", "Tidel Park, Coimbatore"]
    
    var profileObj = ProfileModel()
    var isOtherProfile = Bool()
    
    lazy var country = Country(countryCode: "IN")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
//        profileTableView.backgroundColor = UIColor.white
        if !isOtherProfile {
            self.addEditBarButton()
        }
        
        appVersionLabel.text = ""
        
        if AppVersionVisibility {
            appVersionLabel.text = "App Version: \(Bundle.main.releaseVersionNumber ?? "1.0")#\(Bundle.main.buildVersionNumber ?? "1")(\(BuildTarget))"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
       // self.setNavigationBarItem()
        
        if !isOtherProfile {
            self.getProfileDetails()
            print("profile is of owner = \(isOtherProfile)")
        } else {
            print("profile is of other = \(isOtherProfile)")
            self.listData.removeAll()
            self.listData.append((profileObj.name)!)
            self.listData.append((profileObj.email)!)
            self.listData.append((profileObj.mobile)!)
            self.listData.append((profileObj.address)!)
            print("access granted time = \(profileObj.accessGrantedTime)")
            self.listData.append(profileObj.accessGrantedTime)
            if profileObj.accessGrantedTime != nil {
                
                
       
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                let tempStr = (profileObj.accessGrantedTime)!
//                let dateValue = dateFormatter.date(from: tempStr)!
                let dateValue = Utilities().UTCToLocal(date: profileObj.accessGrantedTime)

//                dateFormatter.dateFormat = "dd-MM-yyyy hh:mm:ss a"
//                 let dateStr =  dateFormatter.string(from: dateValue)
                self.listData.append(dateValue)
            }
        }
    }
    
    func convertDateFormater(_ date: String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let date = dateFormatter.date(from: (profileObj.accessGrantedTime)!)
        
        
        
        
        dateFormatter.dateFormat = "dd-MM-yyyy hh:mm:ss a"
        return  dateFormatter.string(from: date!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Initialize methods
    
    func initialize() {
        self.title = "Profile"
        self.registerTableViewCell()
        self.addBackBarButton()
    }
    
    // MARK: - Navigation Bar Button
    
    func addEditBarButton() {
        
        let editBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        editBtn.addTarget(self, action: #selector(self.onTapProfileEditButton), for: UIControl.Event.touchUpInside)
//        editBtn.setImage(UIImage(named: "back"), for: UIControlState.normal)
        editBtn.setTitle("Edit", for: .normal)
        
        editBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        editBtn.sizeToFit()
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: editBtn)
        self.navigationItem.rightBarButtonItem = customBackBtnItem
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        let nib = UINib.init(nibName: "ProfileTableViewCell", bundle: nil)
        self.profileTableView.register(nib, forCellReuseIdentifier: "ProfileTableViewCell")
    }
    
    // MARK: - Button Actions
    
    @objc func onTapProfileEditButton() {
        self.navigateToEditProfileScreen()
    }
    
    // MARK: - Navigation Methods
    
    func navigateToEditProfileScreen() {

        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let editProfileViewController = storyBoard.instantiateViewController(withIdentifier: "EditProfileViewController") as! EditProfileViewController
        /*
        self.profileObj.name = "(result?.name)!"
        self.profileObj.email = "(result?.email)!"
        self.profileObj.mobile = "(result?.mobile)!"
        self.profileObj.address = "(result?.address)!"
        */
        editProfileViewController.profileObj = self.profileObj
        
        self.navigationController?.pushViewController(editProfileViewController, animated: true)
    }
    
    // MARK: - Service Calls
    
    func getProfileDetails() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "users/profile"
        
        /*
         "username":"spn",
         "password":"Payoda@123",
         "email":"spn@payoda.com",
         "mobile":"7788778877",
         "address":"kdfjvhiek",
         */
        
      
        ProfileViewModel().getProfileViewModel(url: urlString, userDetails: [:], callback: { (result, error) in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // populate data from result and reload table
                
                self.listData.removeAll()
                
                self.listData.append((result?.name)!)
                self.listData.append((result?.email)!)
                self.listData.append((result?.mobile)!)
                self.listData.append((result?.address)!)
               // self.listData.append((result?.accessGrantedTime)!)
                
                //self.listData.append((result?.accessGrantedTime)!)
                
                self.profileObj.name = (result?.name)!
                self.profileObj.email = (result?.email)!
                if let countryCode = result?.countryCode {
                    self.profileObj.countryCode = countryCode
                }else {
                    self.profileObj.countryCode = "IN"
                }
                self.profileObj.mobile = (result?.mobile)!
                self.profileObj.address = (result?.address)!
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                if self.listData.count > 5 {
//                    self.listData[5] = dateFormatter.string(from: Date())
//                } else {
//                     print("listData array doesn't have enough elements to update access granted time")
//                }
                
                self.profileTableView.reloadData()
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        })
    }

    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton

        backBtn.addTarget(self, action: #selector(self.onTapBackButton), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)

        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }

    @objc func onTapBackButton() {
        if isOtherProfile {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.loadMainView()
        }
    }
    
    @objc fileprivate func loadMainView() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController

        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        leftViewController.mainViewController = navigationController

        let slider = SlideMenuController(mainViewController:navigationController, leftMenuViewController: leftViewController)

        slider.automaticallyAdjustsScrollViewInsets = true
        slider.delegate = mainViewController

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        appDelegate.window?.rootViewController = slider
        appDelegate.window?.makeKeyAndVisible()
    }
}


extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell") as? ProfileTableViewCell
            cell?.placeholderLabel.text = listPlaceholserData[indexPath.row]
            cell?.detailLabel.text = listData[indexPath.row]
            cell?.selectionStyle = .none
            
            if(indexPath.row == 2){
                cell?.countryCodeView.isHidden = false
                cell?.dummyLabel.isHidden = false
                cell?.countryCodeButton.isHidden = false
                
                country = Country(countryCode: profileObj.countryCode ?? "US")
                cell?.countryCodeButton.setTitle(country.dialingCode, for: .normal)
                
                CountryManager.shared.resetLastSelectedCountry()
            }else {
                cell?.countryCodeView.isHidden = true
                cell?.dummyLabel.isHidden = true
                cell?.countryCodeButton.isHidden = true
            }
            return cell!
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isOtherProfile {
            return 4
        } else {
            if profileObj.accessGrantedTime != nil {
                return 5
            } else {
                return 4
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return /*UITableView.*/UITableView.automaticDimension
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
