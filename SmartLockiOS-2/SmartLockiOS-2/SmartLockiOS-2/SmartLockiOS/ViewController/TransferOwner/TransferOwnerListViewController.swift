//
//  TransferOwnerListViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 26/10/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class TransferOwnerListViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel?
    @IBOutlet weak var transferOwnerListTableView: UITableView?
    
    var lockListArray = [LockListModel]()
    let refresher = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize method
    func initialize() {
        title = "Lock List"
        transferOwnerListTableView?.separatorStyle = .none
//        transferOwnerListTableView?.backgroundColor = UIColor.white
        addBackBarButton()
        registerTableViewCell()
        getLockListServiceCall()
        infoLabel?.text = EMPTY_LOCK_LIST
    }
    
    // MARK: - Register Cells
    func registerTableViewCell() {
        
        let nib = UINib(nibName: "LockListTableViewCell", bundle: nil)
        self.transferOwnerListTableView?.register(nib, forCellReuseIdentifier: "LockListTableViewCell")
    }
    
    //MARK: - Add refresh controller
    
    func addRefreshController() {
        
        self.refresher.attributedTitle = NSAttributedString(string: "")
        self.refresher.addTarget(self, action: #selector(self.refreshCall), for: .valueChanged)
        self.transferOwnerListTableView?.addSubview(self.refresher)
    }
    
    @objc func refreshCall() {
        
        if Connectivity().isConnectedToInternet() {
            self.getLockListServiceCall()
        } else {
            self.refresher.endRefreshing()
        }
    }
    
    // MARK: - Navigation Bar Button
    
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
        self.loadMainView()
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
    
    // MARK: - Service Call
    @objc func getLockListServiceCall() {
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/locklist"
        
        LockDetailsViewModel().getLockListServiceViewModel(url: urlString, userDetails: [:]) { result, _ in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            if result != nil {
                // populate data from result and reload table
                
                self.lockListArray.removeAll()
                
                self.lockListArray = result as! [LockListModel]
                
                //print("self.lockListArray ==> ")
                //print(self.lockListArray)
                //print("self.lockListArray count ==>")
                //print(self.lockListArray.count)
                
                let filterArray = self.lockListArray.filter({ (lockListModel) -> Bool in
                    
                    return lockListModel.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue && lockListModel.lock_keys![0].status! == "1"
                })
                
                self.lockListArray = filterArray
                
                if self.lockListArray.count > 0 {
                    self.infoLabel?.isHidden = true
                    self.transferOwnerListTableView?.isHidden = false
                } else {
                    self.infoLabel?.isHidden = false
                    self.transferOwnerListTableView?.isHidden = true
                }
                self.transferOwnerListTableView?.reloadData()
                
            } else {
                self.infoLabel?.isHidden = false
            }
        }
    }
}



// MARK: - UITableViewDataSource
extension TransferOwnerListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockListTableViewCell") as? LockListTableViewCell
            cell?.selectionStyle = .none
            
            //            cell?.lockNameLabel.text = lockListArray[indexPath.row]
            let lockListObj = lockListArray[indexPath.row]
            cell?.lockNameLabel.text = lockListObj.lockname
            return cell!
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
    
}

// MARK: - UITableViewDelegate

extension TransferOwnerListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // navigate to lock details
        
        BLELockAccessManager.shared.delegate = nil
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let lockListDetailsObj = lockListArray[indexPath.row]
        
        LockWifiManager.shared.localCache.updateOfflineItems()
        let transferOwnerViewController = storyBoard.instantiateViewController(withIdentifier: "TransferOwnerViewController") as! TransferOwnerViewController
        transferOwnerViewController.transferKeyId = lockListDetailsObj.lock_owner_id![0].id!
        transferOwnerViewController.isAddScreen = true
        transferOwnerViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
        self.navigationController?.pushViewController(transferOwnerViewController, animated: true)

    }
}




