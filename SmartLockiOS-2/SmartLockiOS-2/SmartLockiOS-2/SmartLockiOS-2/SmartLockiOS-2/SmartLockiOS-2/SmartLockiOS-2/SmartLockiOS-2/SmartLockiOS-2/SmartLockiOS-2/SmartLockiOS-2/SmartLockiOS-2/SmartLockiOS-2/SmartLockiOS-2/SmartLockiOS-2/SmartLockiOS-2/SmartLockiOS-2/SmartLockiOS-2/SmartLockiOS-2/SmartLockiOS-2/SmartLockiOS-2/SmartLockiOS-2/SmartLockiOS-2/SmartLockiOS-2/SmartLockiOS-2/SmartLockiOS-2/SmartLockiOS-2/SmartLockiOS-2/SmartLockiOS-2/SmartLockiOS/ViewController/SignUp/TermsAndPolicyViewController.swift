//
//  TermsAndPolicyViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 09/10/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class TermsAndPolicyViewController: UIViewController {

    var titleString: String?
    var customBackBtnItem = UIBarButtonItem()
    var urlString = String()

    @IBOutlet weak var termsWebView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = titleString
        self.addBackBarButton()
        
//        let url = NSURL (string: "http://www.sourcefreeze.com");
        let url = NSURL(string: urlString)
        let requestObj = NSURLRequest(url: url! as URL)
        termsWebView.loadRequest(requestObj as URLRequest);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToRoot), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        self.customBackBtnItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = self.customBackBtnItem
    }
    
    @objc func popToRoot() {        self.navigationController?.popViewController(animated: true)
    }

}
