//
//  ScanPeripheralViewController.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/3/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit

class ScanPeripheralViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BLELockScanControllerProtocol {
    @IBOutlet weak var peripheralTableView: UITableView!
    var closeHandler: ((_ bluetoothHandler:BluetoothAdvertismentData?) -> Void)?
    weak var parentLockListController:LockListViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func initialize(){
        BLELockAccessManager.shared.scanController.scanDelegate = self
        BLELockAccessManager.shared.prolongedScanForPeripherals()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLELockAccessManager.shared.scanController.scannedDevicesList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = UITableViewCell()
        tableCell.textLabel?.text = BLELockAccessManager.shared.scanController.scannedDevicesList[indexPath.row].formattedLocalName
        tableCell.textLabel?.font = UIFont.systemFont(ofSize: 16.0)
        return tableCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let selectedLock = BLELockAccessManager.shared.scanController.scannedDevicesList[indexPath.row]
        BLELockAccessManager.shared.stopPeripheralScan()
        closeHandler?(selectedLock)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    @IBAction func cancelTapped(){
        BLELockAccessManager.shared.stopPeripheralScan()
         self.dismiss(animated: true, completion: nil)
    }

    func didDiscoverNewLock(devices: [BluetoothAdvertismentData]) {
        DispatchQueue.main.async {
            self.peripheralTableView.reloadData()
        }

    }

    func didEndScan() {

    }
}
