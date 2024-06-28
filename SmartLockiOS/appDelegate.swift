//
//  AppDelegate.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 24/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//
//com.astrixengineering.ax100
//com.astrixengineering.ax100.factory
import UIKit
import IQKeyboardManagerSwift
import SlideMenuControllerSwift
import UserNotifications
import FirebaseCore
//import FirebaseInstanceID
import FirebaseMessaging
import CoreData
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import TrustKit
import JailbrokenDetector
import FirebaseAnalytics
import StoreKit
import Network
import FirebaseAuth
import FirebaseFirestore

//@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate , UNUserNotificationCenterDelegate,MessagingDelegate{
    //  var remoteAccessModel = RemoteAccessModel
    var window: UIWindow?
    let reachability = Reachability()!
    let jsonUtils = JsonUtils()
    // Notification center property
    let userNotificationCenter = UNUserNotificationCenter.current()
    let gcmMessageIDKey = "gcm.Message_ID"
    var lockListDetailsObj = LockListModel(json: [:])
    var browser: NWBrowser?
    var fcmTokenGet :String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestLocalNetworkPermission()
        
        let isJailBroken = JailbrokenDetector.isDeviceJailbroken()
        if isJailBroken {
            exit(0)
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Request authorization failed: \(error.localizedDescription)")
                        return
                    }
                    
                    if granted {
                        print("Notification permission granted.")
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                        }
                    } else {
                        print("Notification permission not granted.")
                    }
                }
        window = UIWindow(frame: UIScreen.main.bounds)
        // Set the launch view controller as the root view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LaunchScreenViewController()
        window?.makeKeyAndVisible()
        
        // Simulate a delay (6 seconds in this example)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
        }
         initTrustKit()
          AppCenter.start(withAppSecret: AppCenterKey, services:[
            Analytics.self,
            Crashes.self
        ])
        AppCenter.logLevel = .verbose
        Analytics.trackEvent("App Starts")
        let keychain = KeychainSwift()
        let password = EncryptionPassword
        
        let encryptionKey = EncryptionKey
        let enteredKeyData = encryptionKey.data(using: .utf8)
        let encryptedData = RNCryptor.encrypt(data: enteredKeyData!, withPassword: password)
        keychain.set(encryptedData, forKey: KeychainKeys.encryptionKey.rawValue)
        
        let encryptionIv = EncryptionIv
        let ivData = encryptionIv.data(using: .utf8)
        let encryptedIvData = RNCryptor.encrypt(data: ivData!, withPassword: password)
        keychain.set(encryptedIvData, forKey: KeychainKeys.encryptionIV.rawValue)
        
        
        // Assing self delegate on userNotificationCenter
        self.userNotificationCenter.delegate = self
        self.requestNotificationAuthorization()
        
        NotificationCenter.default.addObserver(self, selector:#selector(self.checkForReachability), name: NSNotification.Name.reachabilityChanged, object: nil)
        
        do {
            try
            self.reachability.startNotifier()
            
        } catch {
            //print("Exception")
        }
        
        //        let reachability: Reachability = Reachability.
        //            .forInternetConnection()
        
        /*UIFont.familyNames.forEach({ familyName in
         let fontNames = UIFont.fontNames(forFamilyName: familyName)
         //print(familyName, fontNames)
         })*/
        
        var targetName = Bundle.main.infoDictionary?["TargetName"] as! String
        if targetName == "Fort" {
            targetName = "GoogleService-Info"
        }
        //        else if targetName == "SmartLockiOSFACTORY"
        //        {
        //            targetName = "GoogleService-Info-AX100Factory"
        //            AppCenter.start(withAppSecret: "557e94aa-c2e7-4012-a798-a5fe95e9cc9b", services:[
        //              Analytics.self,
        //              Crashes.self
        //            ])
        //        }
        //        else if targetName == "TouchPlusFactory"{
        //            targetName = "GoogleService-Info-TouchPlusFactory"
        //            AppCenter.start(withAppSecret: "c232a434-56c6-4e05-bf48-a1e8043a64e9", services:[
        //              Analytics.self,
        //              Crashes.self
        //            ])
        //        }
        //        else if targetName == "TouchPlusFactoryDev"{
        //            targetName = "GoogleService-Info-TouchPlusDev"
        //        }
        //        else if targetName == "SecnorFactory"{
        //            targetName = "GoogleService-Info-SecnorFactory"
        //        }
        //        else {
        //            targetName = "GoogleService-Info-TouchPlus"
        //        }
        
        ServiceUrl.init()
        AppCenter.logLevel = .verbose
        
        let filePath = Bundle.main.path(forResource: Bundle.main.infoDictionary?["GoogleServiceInfo"] as? String, ofType: "plist")!
        
        print("targetName= \(targetName)")
        debugPrint("filePath check = \(filePath)")
        
        let options = FirebaseOptions(contentsOfFile: filePath)
        //FirebaseApp.configure(options: options!)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
       // self.registerForPushNotifications(application: application)
        
        BLELockAccessManager.shared.initialize()
        //       IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(EditScheduleAccessViewController.self)
        IQKeyboardManager.shared.disabledToolbarClasses.append(EditScheduleAccessViewController.self)
        
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = UIColor.lightGray
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font:UIFont.setRobotoMedium18FontForTitle]
        
        UINavigationBar.appearance().barStyle = .blackOpaque
        
        if let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) {
            
            if authToken != nil {
                print("if already login 'if' workes")// already logged in
                //Update the latest device token
                updateDeviceToken(withToken: authToken)
                
                let keychain = KeychainSwift()
                let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
                if decryptValue != nil { // already pin set
                    // load validate pin
                    LockWifiManager.shared.localCache.updateOfflineItems()
                    self.loadPinValidationScreen()
                } else {
                    // load create pin
                    self.loadCreatePinVC()
                }
            } 
        } else {
            print("already not logged in ")
            // load Sign in
            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
                updateDeviceToken(withToken: fcmToken)
            }
                let keychain = KeychainSwift()
                keychain.delete(KeychainKeys.securityPin.rawValue)
                self.loadSignInVC()
            
        }
        
       // self.registerForPushNotifications(application: application)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.applicationDidTimeout(notification:)),
                                               name: .appTimeout,
                                               object: nil
        )
        
        NotificationCenter.default.addObserver(forName: .acceptAction, object: nil, queue: nil) { notification in
        }
        NotificationCenter.default.addObserver(forName: .rejectAction, object: nil, queue: nil) { notification in
        }
//        if isFirstLaunchAfterInstallation() {
//                    // Delete the cached FCM token
//                    deleteFCMToken { success in
//                        if success {
//                            print("Successfully deleted cached FCM token")
//                            // Fetch a new FCM token
//                            self.fetchFCMToken()
//                        } else {
//                            print("Error deleting cached FCM token")
//                        }
//                    }
//                } else if isUserLoggedIn() {
//                    fetchFCMToken()
//                }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        if authToken != nil {
            let keychain = KeychainSwift()
            let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
            if decryptValue != nil {
                LockWifiManager.shared.localCache.updateOfflineItems()
                let defaults = UserDefaults.standard
                defaults.set(Utilities().getCurrentTimestamp(), forKey: "idleTime")
                defaults.synchronize()
            }
        }
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        if authToken != nil {
            //Update the latest device token to server
           // self.updateDeviceToken()
            
            let keychain = KeychainSwift()
            let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
            if decryptValue != nil {
                LockWifiManager.shared.localCache.updateOfflineItems()
                self.calculateIdleTime()
            }
        }
        
        let isLockListScreen = UserDefaults.standard.bool(forKey: "isLockListScreen")
        
        if isLockListScreen {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "connectedToWIFI"), object: nil)
        }
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0;
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        Messaging.messaging().deleteToken { error in
                    if let error = error {
                        print("Error deleting FCM token: \(error)")
                    } else {
                        print("FCM token deleted. Requesting new token...")
                    }
                }
        self.saveContext()
    }
    func requestLocalNetworkPermission() {
        let parameters = NWParameters.udp
        let browser = NWBrowser(for: .bonjour(type: "_lnp._tcp", domain: nil), using: parameters)
        browser.browseResultsChangedHandler = { results, changes in
            // Handle browse results and changes
        }
        browser.start(queue: .main)
        
        // Keep a reference to the browser to keep it alive
        self.browser = browser
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("DEVICETOKEN \(deviceToken)")
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "Push_Token")
        print("Device token:", token)
        
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let fcmToken = fcmToken else {
            print("FCM token is nil")
            return
        }
        fcmTokenGet = fcmToken
        print("fcm token recieved = \(fcmTokenGet)")
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        UserDefaults.standard.synchronize()
        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        
        // Send token to application server
        print("update device token when app recieve fcm token")
        updateDeviceToken(withToken: fcmToken)
    }
    func updateDeviceToken(withToken token: String) {
//        guard let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue) else {
//            print("Auth token is not available. Device token update deferred.")
//            return
//        }
        
        if Connectivity().isConnectedToInternet() {
            let appid = "2"
            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken"), !fcmToken.isEmpty {
           // if let fcmToken = fcmTokenGet {
                let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
                print("Device token recieved for update \(fcmToken)")
                
               let urlString = ServiceUrl.BASE_URL + "users/updatetoken"
                let tokenDetails = ["deviceToken": fcmToken,
                                    "appid": appid,
                                    "authToken": authToken] as [String: AnyObject]
//                let tokenDetails = ["deviceToken": fcmToken,
//                                    "appid": appid] as [String: AnyObject]
                print("Token details for update device token \(tokenDetails)")
                
                DataStoreManager().updateDeviceTokenDataStore(url: urlString, tokenDetails: tokenDetails) { (result, error) in
                    if let error = error {
                        let errorMessage = error.userInfo["ErrorMessage"] as? String ?? "Unknown error"
                        print("Device token update error: \(errorMessage)")
                        return
                    }
                    
                    if let result = result {
                        if let data = result["data"].rawString() {
                            print("Server response: \(data)")
                        } else {
                            print("Device token update success, but no data returned")
                        }
                    }
                }
            } else {
                print("Device token is not stored in UserDefaults")
            }
        }
    }
   

    func remoteActivity(serialNumber: String, lockStatus: String, request_id: String, completion: @escaping (String) -> Void) {
        let tokenDetails: [String: AnyObject] = [
            "lock-serial-no": serialNumber as AnyObject,
            "lock_status": lockStatus as AnyObject,
            "request_id": request_id as AnyObject
        ]
        
        let urlString = ServiceUrl.BASE_URL + "activities/remote_activity"
        print("url ==> \(urlString)")
        
        DataStoreManager().remoteActivityDataStore(url: urlString, tokenDetails: tokenDetails) { (result, error) in
            if let result = result {
                if let message = result["message"].string {
                    print("Remote activity response --> \(message)")
                    completion(message)
                } else {
                    completion("Unknown response")
                }
            } else if let error = error {
                let message = error.userInfo["ErrorMessage"] as? String ?? "Unknown error"
                print("Remote activity error --> \(message)")
                completion("Remote activity error: \(message)")
            }
        }
    }

    func parseResponse(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let message = json?["message"] as? String {
                print("message = \(message)")
                return message
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }


    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification called")
        //print("sm pn \(userInfo.debugDescription)")
        if let messageID = userInfo[gcmMessageIDKey] {
          print("Message ID: \(messageID)")
        }

        // Print full message.
        print("@@@@@@@\(userInfo)")

        completionHandler(UIBackgroundFetchResult.newData)
        self.handleRemoteNotificationData(userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        self.handleRemoteNotificationData(userInfo: userInfo)
    }

    func initTrustKit(){
        var baseUrl = Bundle.main.infoDictionary?["ENDPOINT_URL"] as! String
        //baseUrl = baseUrl.replacingOccurrences(of: "https://fortstaging.co.in", with: "")
        baseUrl = baseUrl.replacingOccurrences(of: "http://", with: "")
        TrustKit.setLoggerBlock { (message) in
            debugPrint("TrustKit log: \(message)")
        }
        
        let trustKitConfig: [String: Any] = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                baseUrl: [
                    kTSKEnforcePinning: true,
                    kTSKIncludeSubdomains: true,
                    kTSKPublicKeyHashes: [
//                    publicKeyHash1,
//                    publicKeyHash2,
                      "r1crQfSreVIh0mVOA+ssxKoVSNK7YjagWAMAL1F7lKM=",
                      "8Z75TAQ/CZxZWxkDIyPVF9vMY0z8novGaQfKeRXFkIo="
                    ],
                    kTSKReportUris:[],
                ],
            ]]
       
        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
    }
    func handleRemoteNotificationData(userInfo: [AnyHashable: Any]) {
        debugPrint("handleRemoteNotificationData --> \(userInfo)")
        
        if let aps = userInfo["aps"] as? [String: Any] {
            if let contentAvailable = aps["content-available"] as? Bool, contentAvailable {
             } else if let alert = aps["alert"] as? [String: Any] {
                let alertTitle = alert["title"] as? String
                let alertBody = alert["body"] as? String
                let status = userInfo["status"] as? String
                let command = userInfo["command"] as? String
                 let content = UNMutableNotificationContent()
                 let alertController = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
                
                 let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                 userNotificationCenter.add(request)
                // Add action buttons
                let acceptAction = UIAlertAction(title: "Accept", style: .default) { _ in
                     NotificationCenter.default.post(name: .acceptAction, object: nil, userInfo: userInfo)
                }
                let rejectAction = UIAlertAction(title: "Reject", style: .destructive) { _ in
                     NotificationCenter.default.post(name: .rejectAction, object: nil, userInfo: userInfo)
                }
                alertController.addAction(acceptAction)
                alertController.addAction(rejectAction)
                
                if let topViewController = UIApplication.topViewController() {
                    topViewController.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: - Timer Notification
    @objc func applicationDidTimeout(notification: NSNotification) {
         let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        
        if authToken != nil { // already logged in
            let keychain = KeychainSwift()
            let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
            if decryptValue != nil { // already pin set
                // load validate pin
                self.loadPinValidationScreen()
            } else {
                // load create pin
                self.loadCreatePinVC()
            }
        } else {
            // load Sign in
            let keychain = KeychainSwift()
            keychain.delete(KeychainKeys.securityPin.rawValue)
            //            self.loadSignInVC()
        }
    }
    
    // MARK: - Register push notification
     func registerForPushNotifications(application: UIApplication) {
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             if granted {
                 DispatchQueue.main.async {
                     application.registerForRemoteNotifications()
                 }
             } else {
                 // Handle permission denial or error
                 print("User denied notification permissions")
             }
         }
        }
//    func registerForPushNotifications() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
//            (granted, error) in
//            //print("Permission granted: \(granted)")
//            guard granted else { return }
//            self.getNotificationSettings()
//        }
//    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            //print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo = response.notification.request.content.userInfo
//        
//        if let messageBody = response.notification.request.content.body as? String, messageBody == "Remote User Access." {
//           
//            let alert = UIAlertController(title: "FORT", message: messageBody, preferredStyle: .alert)
//            
//            let action1 = UIAlertAction(title: "Accept", style: .default) { _ in
//                // Handle Accept action
//            }
//            alert.addAction(action1)
//            
//            let action2 = UIAlertAction(title: "Reject", style: .default) { _ in
//                // Handle Reject action
//            }
//            alert.addAction(action2)
//            
//            // Present the alert
//            if let topViewController = UIApplication.topViewController() {
//                DispatchQueue.main.async {
//                    topViewController.present(alert, animated: true, completion: nil)
//                }
//            }
//        }
//        
//        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        Messaging.messaging().appDidReceiveMessage(userInfo)
//        
//        // Print full message.
//        print("Received notification: \(userInfo)")
//        completionHandler()
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let statusString = userInfo[AnyHashable("status")] as? String {
            print("Value of 'gcm.notification.status': \(statusString)")
            let statusComponents = statusString.split(separator: ",")
            if statusComponents.count == 2 {
                let request_id = String(statusComponents[0])
                let lock_serial_number = String(statusComponents[1])
                print("Request ID: \(request_id), Lock Serial Number: \(lock_serial_number)")
                
                if let messageBody = response.notification.request.content.body as? String, messageBody == "Remote User Access." {
                    let alert = UIAlertController(title: "FORT", message: messageBody, preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "Accept", style: .default) { _ in
                        let lockStatus = "1"
                        self.remoteActivity(serialNumber: lock_serial_number, lockStatus: lockStatus, request_id: request_id) { responseMessage in
                            DispatchQueue.main.async {
                                self.window?.makeToast(responseMessage)
                                print("the message is \(responseMessage)")
                            }
                        }
                    }
                    alert.addAction(action1)
                    
                    let action2 = UIAlertAction(title: "Reject", style: .default) { _ in
                        let lockStatus = "0"
                        self.remoteActivity(serialNumber: lock_serial_number, lockStatus: lockStatus, request_id: request_id) { responseMessage in
                            // Handle the response message here
                            DispatchQueue.main.async {
                                self.window?.makeToast(responseMessage)
                                print(responseMessage)
                            }
                        }
                    }
                    alert.addAction(action2)
                    
                    // Present the alert
                    if let topViewController = UIApplication.topViewController() {
                        DispatchQueue.main.async {
                            topViewController.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print("Received notification: \(userInfo)")
        completionHandler()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        if let statusString = userInfo[AnyHashable("status")] as? String {
            print("Value of 'gcm.notification.status': \(statusString)")
            let statusComponents = statusString.split(separator: ",")
            if statusComponents.count == 2 {
                let request_id = String(statusComponents[0])
                let lock_serial_number = String(statusComponents[1])
                print("Request ID: \(request_id), Lock Serial Number: \(lock_serial_number)")
                
                if let messageBody = notification.request.content.body as? String, messageBody == "Remote User Access." {
                    let alert = UIAlertController(title: "FORT", message: messageBody, preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "Accept", style: .default) { _ in
                        let lockStatus = "1"
                        self.remoteActivity(serialNumber: lock_serial_number, lockStatus: lockStatus, request_id: request_id) { responseMessage in
                            DispatchQueue.main.async {
                                self.window?.makeToast(responseMessage)
                                print("the message is \(responseMessage)")
                            }
                        }
                    }
                    alert.addAction(action1)
                    
                    let action2 = UIAlertAction(title: "Reject", style: .default) { _ in
                        let lockStatus = "0"
                        self.remoteActivity(serialNumber: lock_serial_number, lockStatus: lockStatus, request_id: request_id) { responseMessage in
                            // Handle the response message here
                            DispatchQueue.main.async {
                                self.window?.makeToast(responseMessage)
                                print(responseMessage)
                            }
                        }
                    }
                    alert.addAction(action2)
                    
                    // Present the alert
                    if let topViewController = UIApplication.topViewController() {
                        DispatchQueue.main.async {
                            topViewController.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        
        // Ensure message is received properly
        Messaging.messaging().appDidReceiveMessage(userInfo)
        print("Received notification: \(userInfo)")
        return [.alert, .sound]
    }

    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        
        self.userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }
    
    func triggerLocalNotification(title: String, body:String) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)
        let uuid = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuid,
                                            content: notificationContent,
                                            trigger: trigger)
        
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                debugPrint("Notification Error: ", error)
            }
        }
    }

    
    // MARK: - Calculate Idle time
    
    func calculateIdleTime() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let defaults = UserDefaults.standard
        let savedTimeStamp = defaults.string(forKey: "idleTime")
        //print("currentTimeStamp")
        
        var savedTime = Date()
        savedTime = dateFormatter.date(from: savedTimeStamp!)!
        
        let currentTimeStamp = Utilities().getCurrentTimestamp()
        var currentTime = Date()
        currentTime = dateFormatter.date(from: currentTimeStamp)!
        
        
        let timeInterval = currentTime.timeIntervalSince(savedTime)
        
        //print("timeInterval ==> \(timeInterval)")
        
        if timeInterval > 60 {
            self.loadPinValidationScreen()
        }
    }
    
    @objc func checkForReachability(notification:NSNotification)
    {
        // Remove the next two lines of code. You cannot instantiate the object
        // you want to receive notifications from inside of the notification
        // handler that is meant for the notifications it emits.
        
        //var networkReachability = Reachability.reachabilityForInternetConnection()
        //networkReachability.startNotifier()
        
        //print("Notification =====>")
        //print(notification)
        
        let networkReachability = notification.object as! Reachability;
        let remoteHostStatus = networkReachability.connection
        
        //print("remoteHostStatus.description ==> \(remoteHostStatus.description)")
        if remoteHostStatus.description == "No Connection" {
            
        } else { // Cellular, WiFi
            let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
            if authToken != nil {
                let keychain = KeychainSwift()
                let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
                if decryptValue != nil {
                    debugPrint("called from appdelegate")
                    LockWifiManager.shared.localCache.updateOfflineItems()
                }
            }
        }
        /*
         let networkReachability = notification.object as! Reachability;
         var remoteHostStatus = networkReachability.currentReachabilityStatus()
         
         if (remoteHostStatus.value == NotReachable.value)
         {
         println("Not Reachable")
         }
         else if (remoteHostStatus.value == ReachableViaWiFi.value)
         {
         println("Reachable via Wifi")
         }
         else
         {
         println("Reachable")
         }*/
    }
    
    // MARK: - Navigation Methods
    
    fileprivate func loadMainView() {
        
        // create viewController code...
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        
        //            let nvc: UINavigationController = UINavigationController(rootViewController: mainViewController)
        
        
        leftViewController.mainViewController = navigationController
        
        
        let slider = SlideMenuController(mainViewController:navigationController, leftMenuViewController: leftViewController)
     
        slider.automaticallyAdjustsScrollViewInsets = true
        slider.delegate = mainViewController
        //            self.window?.backgroundColor = UIColor(red: 236.0, green: 238.0, blue: 241.0, alpha: 1.0)
        self.window?.rootViewController = slider
        self.window?.makeKeyAndVisible()
        
    }
    
    func loadSignInVC() {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        let navigationController = UINavigationController(rootViewController: signInViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        
        self.window?.rootViewController = navigationController
        
    }
    
    func loadPinValidationScreen() {
        let rootViewController = self.window!.rootViewController
        
        let storyBoardId = UIStoryboard(name: "Main", bundle: nil)
        let pinValidationVC = storyBoardId.instantiateViewController(withIdentifier: "ValidatePinViewController") as! ValidatePinViewController
        pinValidationVC.isFromAppdelegate = true
        
        let navController = UINavigationController(rootViewController: pinValidationVC)
        navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navController.navigationBar.shadowImage = UIImage()
        navController.navigationBar.isTranslucent = true
        self.window?.rootViewController = navController
        
    }
    
    func loadCreatePinVC() {
        let rootViewController = self.window!.rootViewController
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let pinViewController = storyBoard.instantiateViewController(withIdentifier: "PinViewController") as! PinViewController
        pinViewController.isFromLogin = true
        pinViewController.isFromResetPIN = false
        let navController = UINavigationController(rootViewController: pinViewController)
        navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navController.navigationBar.shadowImage = UIImage()
        navController.navigationBar.isTranslucent = true
        self.window?.rootViewController = navController
        //        rootViewController!.present(navController , animated: false, completion: nil)
    }
    
    
    func printTopView(){
        let top = UIApplication.topViewController()!
        if let viewController = top.self as? SlideMenuController{
            let viewControllers = viewController.mainViewController?.children
            if viewControllers != nil  {
                if viewControllers!.count > 0 {
                    let mainViewController = viewControllers![0] as? MainViewController
                    let currentViewController = mainViewController!.currentViewController() as? NotificationsViewController
                    if currentViewController != nil{
                        
                    }
                }
                
            }
            
        }
        //print("top \(String(describing: type(of: top)))")
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "LockListDataModel")
        /*add necessary support for migration*/
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions =  [description]
        /*add necessary support for migration*/
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

extension Notification.Name {
    static let acceptAction = Notification.Name("AcceptAction")
    static let rejectAction = Notification.Name("RejectAction")
}

