//
//  LoaderView.swift
//  SmartLockPocApp
//
//  Created by Geethanjali Natarajan on 11/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class LoaderView: NSObject {
    
    static let sharedInstance = LoaderView()
    var shadowView: SFShadowView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
//    static let sharedInstance = LoaderView()
//        var shadowView: SFShadowView!
//        let appDelegate: AppDelegate
//        
//    private override init() {
//        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
//    }
    //MARK: -Shadow View for loading status
    
    //Example: Loading screens for different screens
    
    /*
     1. Screens with tabbar
     
     SFSignletonUtility.sharedInstance.showShadowView("Loading...", selfObject: self)
     SFSignletonUtility.sharedInstance.hideShadowView(self)
     
     2. Screens with local notification
     
     SFSignletonUtility.sharedInstance.showShadowView("Loading...", selfObject: self, isFromNotifiation: isFromLocalNotification)
     SFSignletonUtility.sharedInstance.hideShadowView(self, isFromNotifiation: self.isFromLocalNotification)
     
     3. Screens with push notification
     
     SFSignletonUtility.sharedInstance.showShadowView("Loading...", selfObject: self, isFromNotifiation: isFromPushNotification)
     SFSignletonUtility.sharedInstance.hideShadowView(self, isFromNotifiation: self.isFromPushNotification)
     
     4. Screens without tabbar and notifications
     
     SFSignletonUtility.sharedInstance.showShadowView("Loading...", selfObject: self, isFromNotifiation: true)
     SFSignletonUtility.sharedInstance.hideShadowView(self, isFromNotifiation: true)
     
     */
    
    //For normal screens with tab bar
    func showShadowView(title:NSString, selfObject:AnyObject) {
        
        self.addShadowView(title: title, selfObject: selfObject, withtabBar: false)
    }
    
    func hideShadowView(selfObject:AnyObject) {
        
        self.removeShadowView(selfObject: selfObject, withtabBar: false)
    }
    
    //For screens from notification(without tab bar)
    func showShadowView(title:NSString, selfObject:AnyObject, isFromNotifiation:Bool) {

        self.addShadowView(title: title, selfObject: selfObject, withtabBar: !isFromNotifiation)
    }

    func showShadowView(title:NSString, isFromNotifiation:Bool) {
        let selfObject = UIApplication.topViewController()!
        self.addShadowView(title: title, selfObject: selfObject, withtabBar: !isFromNotifiation)
    }

    func hideShadowview() {
        let selfObject = UIApplication.topViewController()!
        hideShadowView(selfObject: selfObject)
    }

    func hideShadowView(selfObject:AnyObject,isFromNotifiation:Bool) {
//        guard let selfObject = selfObject else {
//                   print("selfObject is nil, it was deallocated")
//                   return
//               }
        self.removeShadowView(selfObject: selfObject, withtabBar: !isFromNotifiation)
    }
    
    func addShadowView(title:NSString, selfObject:AnyObject, withtabBar:Bool) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            if (self.shadowView == nil) {
                self.shadowView = SFShadowView(nibName: "SFShadowView", bundle: nil)
        }
        
            self.shadowView.view.frame = CGRect(x: 0, y: 0, width: selfObject.view.frame.size.width, height: selfObject.view.frame.size.height)

            self.shadowView.viewContainer.alpha = 0.8
            self.shadowView.view .isHidden = false
            self.shadowView.activityLabel.text = title as String
            self.shadowView.activityLabel.minimumScaleFactor = 0.5
            selfObject.view .addSubview(self.shadowView.view)
        }
    }
    
    func removeShadowView(selfObject:AnyObject, withtabBar:Bool) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
        if let _:AnyObject = selfObject.tabBarController {
            if selfObject.tabBarController! != nil {
                selfObject.tabBarController?!.tabBar.isUserInteractionEnabled = true
                selfObject.navigationController!!.navigationBar.isUserInteractionEnabled = true
            }
        }
            if (self.shadowView == nil) {
            return
        }

            self.shadowView.view .removeFromSuperview()
        }
    }
    
}
