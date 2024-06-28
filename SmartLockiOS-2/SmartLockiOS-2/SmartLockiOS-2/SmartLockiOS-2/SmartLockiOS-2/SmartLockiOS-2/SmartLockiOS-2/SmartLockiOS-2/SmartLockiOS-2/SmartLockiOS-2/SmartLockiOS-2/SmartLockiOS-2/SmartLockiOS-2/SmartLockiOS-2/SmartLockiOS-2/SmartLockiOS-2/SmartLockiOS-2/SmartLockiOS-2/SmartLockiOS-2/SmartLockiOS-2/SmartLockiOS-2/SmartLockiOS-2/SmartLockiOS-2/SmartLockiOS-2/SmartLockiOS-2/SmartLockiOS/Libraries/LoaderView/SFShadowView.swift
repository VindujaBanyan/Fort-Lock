//
//  SFShadowView.swift
//  StayFit
//
//  Created by ArunPrasanth R on 27/10/15.
//  Copyright © 2015 Payoda. All rights reserved.
//

import UIKit

class SFShadowView: UIViewController {

    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var activityLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        activityView.layer .cornerRadius = 10.0
        activityView.layer .shadowColor = UIColor.black.cgColor
        activityView.layer .shadowOpacity = 0.6
        activityView.layer .shadowOffset = CGSize(width: 0, height: 0)
        activityView.layer .shadowRadius = 1.0
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
