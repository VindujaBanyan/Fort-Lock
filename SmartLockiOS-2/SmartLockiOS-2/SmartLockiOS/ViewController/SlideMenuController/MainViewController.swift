//
//  MainViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 04/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

import SlideMenuControllerSwift
import XLPagerTabStrip

class MainViewController: BaseButtonBarPagerTabStripViewController<TabsCollectionViewCell>, SlideMenuControllerDelegate {

    let redColor = UIColor(red: 221/255.0, green: 0/255.0, blue: 19/255.0, alpha: 1.0)
    let unselectedIconColor = UIColor(red: 73/255.0, green: 8/255.0, blue: 10/255.0, alpha: 1.0)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "TabsCollectionViewCell", bundle: Bundle(for: TabsCollectionViewCell.self), width: { _ in
            return 70.0
        })
    }
    
    override func viewDidLoad() {
        self.title = "Dashboard"
        
        // change selected bar color
        
        settings.style.buttonBarBackgroundColor = UIColor.clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = UIColor(red: 234/255.0, green: 234/255.0, blue: 234/255.0, alpha: 1.0)
        settings.style.selectedBarHeight = 4.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .white
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        
        self.settings.style.selectedBarHeight = 0
        self.settings.style.selectedBarBackgroundColor = TABS_BGCOLOR //UIColor.orange
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: TabsCollectionViewCell?, newCell: TabsCollectionViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            //            oldCell?.iconImage.tintColor = self?.unselectedIconColor
            //            oldCell?.iconLabel.textColor = self?.unselectedIconColor
            //            newCell?.iconImage.tintColor = .white
            //            newCell?.iconLabel.textColor = .white
            
            oldCell?.iconImage.tintColor = .white
            oldCell?.iconLabel.textColor = .white
            newCell?.iconImage.tintColor = TABS_BGCOLOR //.orange
            newCell?.iconLabel.textColor = TABS_BGCOLOR //.orange
            
        }
        super.viewDidLoad()
        
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavigationBarItem()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        
        //        let child_1 = TableChildExampleViewController(style: .plain, itemInfo: IndicatorInfo(title: " HOME", image: UIImage(named: "home")))
        //        let child_2 = TableChildExampleViewController(style: .plain, itemInfo: IndicatorInfo(title: " TRENDING", image: UIImage(named: "trending")))
        //        let child_3 = ChildExampleViewController(itemInfo: IndicatorInfo(title: " ACCOUNT", image: UIImage(named: "profile")))
        
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let lockListViewController = storyBoard.instantiateViewController(withIdentifier: "LockListViewController") as! LockListViewController
        
        let notificationsViewController = storyBoard.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        
        let requestViewController = storyBoard.instantiateViewController(withIdentifier: "RequestViewController") as! RequestViewController
        
        return [lockListViewController, notificationsViewController, requestViewController]
    }
    
    override func configure(cell: TabsCollectionViewCell, for indicatorInfo: IndicatorInfo) {
        cell.iconImage.image = indicatorInfo.image?.withRenderingMode(.alwaysTemplate)
        cell.iconLabel.text = indicatorInfo.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        //cell.badgeLabel.text = indicatorInfo.
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
//        //print("To index ==> \(toIndex)")
        
        if indexWasChanged && toIndex > -1 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider // swiftlint:disable:this force_cast
            UIView.performWithoutAnimation({ [weak self] () -> Void in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title =  child.indicatorInfo(for: me).title
            })
        }
    }

    func currentViewController() -> UIViewController {
        let viewController = self.viewControllers(for: PagerTabStripViewController())[currentIndex]
        return viewController
    }

    @nonobjc func leftWillOpen() {
        //print("SlideMenuControllerDelegate: leftWillOpen")
    }
    
    @nonobjc func leftDidOpen() {
        //print("SlideMenuControllerDelegate: leftDidOpen")
    }
    
    @nonobjc func leftWillClose() {
        //print("SlideMenuControllerDelegate: leftWillClose")
    }
    
    @nonobjc func leftDidClose() {
        //print("SlideMenuControllerDelegate: leftDidClose")
    }
    
    @nonobjc func rightWillOpen() {
        //print("SlideMenuControllerDelegate: rightWillOpen")
    }
    
    @nonobjc func rightDidOpen() {
        //print("SlideMenuControllerDelegate: rightDidOpen")
    }
    
    @nonobjc func rightWillClose() {
        //print("SlideMenuControllerDelegate: rightWillClose")
    }
    
    @nonobjc func rightDidClose() {
        //print("SlideMenuControllerDelegate: rightDidClose")
    }
}

extension UIViewController {
    
    func setNavigationBarItem() {
        self.addLeftBarButtonWithImage(UIImage(named: "menu")!)
        self.slideMenuController()?.removeLeftGestures()
        self.slideMenuController()?.addLeftGestures()
    }
    
    func removeNavigationBarItem() {
        self.navigationItem.leftBarButtonItem = nil
        self.slideMenuController()?.removeLeftGestures()
    }
}
