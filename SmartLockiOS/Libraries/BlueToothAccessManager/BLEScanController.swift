//
//  BLEScanController.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/4/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import CoreBluetooth
private protocol BLELockAccessManagerScanProtocol {
    func didDiscoverNewLock(lockData: BluetoothAdvertismentData)
}
protocol BLELockScanControllerProtocol:class {
    func didDiscoverNewLock(devices: [BluetoothAdvertismentData])
    func didEndScan()
}

typealias BLEProactiveCompletionBlock = (_ serialNumber:String?,_ lock:BluetoothAdvertismentData) -> Void

class BLEScanController:BLELockAccessManagerScanProtocol  {
    weak var scanDelegate: BLELockScanControllerProtocol?
    var proactiveScanCompletionBlock:BLEProactiveCompletionBlock?
    var scannedDevicesList:[BluetoothAdvertismentData] = []
    var possibleNextLock:BluetoothAdvertismentData?
    var isProactiveScanning:Bool = false
    var proactiveSerialNumber:String?
    func didDiscoverNewLock(lockData: BluetoothAdvertismentData) {
        if !scannedDevicesList.contains(where: {$0.manufactureData == lockData.manufactureData}){
        scannedDevicesList.append(lockData)
            if isProactiveScanning{
                if self.proactiveSerialNumber != nil {
                    if lockData.formattedLocalName == self.proactiveSerialNumber!{
                        //print("found by proactive scan")
                        self.possibleNextLock = lockData
                        self.proactiveScanCompletionBlock?(self.proactiveSerialNumber,lockData)
                        self.stopPeripheralScan()
                    }
                }
            }
            //print("adding \(lockData.localName)")
        }
        scanDelegate?.didDiscoverNewLock(devices: scannedDevicesList)
    }
    func scanForPeripherals() {
        scannedDevicesList = []
        BluetoothAccessManager.shared.scanForPeripherals()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopPeripheralScan()
        }
    }

    func prolongedScanForPeripherals() {
        scannedDevicesList = []
        BluetoothAccessManager.shared.scanForPeripherals()
        DispatchQueue.main.asyncAfter(deadline: .now() + BLE_ACTIVE_TIME) { // 30.0
            self.stopPeripheralScan()
        }
    }

    func quickScanForPeripheral(){
        scannedDevicesList = []
        BluetoothAccessManager.shared.scanForPeripherals()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.stopPeripheralScan()
        }
    }

    func proactiveScanning(serialNumber:String,completionBlock:BLEProactiveCompletionBlock? = nil) {
        self.stopPeripheralScan()
        self.proactiveScanCompletionBlock = completionBlock
        let matching = self.matchingPeripheral("", serialNumber)
        if possibleNextLock?.formattedLocalName == serialNumber {
            self.proactiveScanCompletionBlock?(serialNumber,self.possibleNextLock!)
            return
        }
        else if (matching != nil){
            self.possibleNextLock = matching
            self.proactiveScanCompletionBlock?(serialNumber,matching!)
            return
        }
        else{
            //print("start pro active scanning")
            BluetoothAccessManager.shared.scanForPeripherals()
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.stopPeripheralScan()
            }
            self.isProactiveScanning = true
        }
    }

    func resetProactiveScan(){
        self.isProactiveScanning = false
        self.proactiveSerialNumber = nil
        self.possibleNextLock = nil
        self.proactiveScanCompletionBlock = nil
    }

    func stopPeripheralScan() {
        print("stop scanning")
        BluetoothAccessManager.shared.stopScanForPeripherals()
        self.scanDelegate?.didEndScan()
        self.isProactiveScanning = false
    }
    func initializeScanner() {
       _ = BLELockAccessManager.shared.checkForBluetoothAccess()
        //scanForPeripherals()
    }
    func matchingPeripheral(_ lockUUID:String, _ serialNumber:String) -> BluetoothAdvertismentData?{
        let originalNumber = JsonUtils().getManufacturerCode() + serialNumber
        var matching:BluetoothAdvertismentData? = nil
        //matching = scannedDevicesList.first{$0.peripheral?.name == originalNumber}
        matching = scannedDevicesList.first{$0.localName == originalNumber}
        if matching?.peripheral == nil {
            return nil
        }
        return matching
    }

    func retrievePeripheral(uuidString uuid:String) -> BluetoothAdvertismentData?{
      let peripheral =  BluetoothManager.getInstance().retrievePeripheral(uuidString: uuid)
        if peripheral == nil {
            return nil
        }
        else{
            var bluetoothAdvertisment = BluetoothAdvertismentData()
            bluetoothAdvertisment.localName = peripheral?.name ?? ""
            bluetoothAdvertisment.peripheral = peripheral
            return bluetoothAdvertisment
        }
    }

}
