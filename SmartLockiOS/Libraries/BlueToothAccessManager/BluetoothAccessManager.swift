//
//  BluetoothAccessManager.swift
//  BluetoothAccess
//
//  Created by Dhilip on 6/17/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
struct BluetoothAccessState {
    var canAccess:Bool = false
    var errorMessage:String = ""
}
struct LocationAccessState {
    var canAccess:Bool = false
    var errorMessage : String = ""
}
protocol AccessState {
    var canAccess: Bool { get }
    var errorMessage: String { get }  
}

struct BluetoothAdvertismentData {
    var rssi:Int = 0
    var localName = ""
    var manufactureData = ""
    var serialNumber = ""
    var peripheral:CBPeripheral?
    var formattedLocalName:String{
        if !localName.isEmpty{
           return localName.replacingOccurrences(of: JsonUtils().getManufacturerCode(), with: "")
        }
        return ""
    }
}

protocol BluetoothAccessManagerDelegate {
    func didDiscoverNewLock(lockData:BluetoothAdvertismentData)
    func didFailedToConnect(error:String)
    func didFinishReadingAllCharacteristics()
    func didDisconnectPeripheral()
}

class BluetoothAccessManager:NSObject,BluetoothDelegate{
    let bluetoothManager = BluetoothManager.getInstance()
    static var shared:BluetoothAccessManager = BluetoothAccessManager()
    var nearbyPeripherals : [CBPeripheral] = []
    var nearbyPeripheralInfos : [CBPeripheral:BluetoothAdvertismentData] = [CBPeripheral:BluetoothAdvertismentData]()
    var isScanInProgress = false
    var delegate:BluetoothAccessManagerDelegate?
    var connectedLock :CBPeripheral?
    var lockService:CBService?
    var currentRequest:BLERequest?
    override init() {
        super.init()
    }

    func initialize(){
        bluetoothManager.delegate = self
    }

    func checkForBluetoothAccess() -> BluetoothAccessState {
        var bluetoothAccessState = BluetoothAccessState()
        if bluetoothManager._manager?.state == .poweredOn{
            bluetoothAccessState.canAccess = true

        }
        else if bluetoothManager._manager?.state == .unauthorized{
            bluetoothAccessState.errorMessage = TURN_ON_BLUETOOTH
        }
        else if bluetoothManager._manager?.state == .poweredOff{
            bluetoothAccessState.errorMessage = TURN_ON_BLUETOOTH
        }
        else if bluetoothManager._manager?.state == .unsupported{
            bluetoothAccessState.errorMessage = "This device does not support BLE"
        }
        else {
            bluetoothAccessState.errorMessage = TURN_ON_BLUETOOTH
        }
        return bluetoothAccessState
    }
    
        func checkForLocationAccess() -> LocationAccessState {
        var locationAccessState = LocationAccessState()
        let locationManager = CLLocationManager()

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            locationAccessState.canAccess = true
        case .denied, .restricted:
            locationAccessState.errorMessage = "Location access denied. Please enable it in Settings."
        case .notDetermined:
            // Request location access
            locationManager.requestWhenInUseAuthorization()
            // You might need to handle the result of the authorization request asynchronously
            // and update the locationAccessState accordingly
        @unknown default:
            locationAccessState.errorMessage = "Unknown location access status."
        }

        return locationAccessState
    }
    


    func scanForPeripherals(){
        nearbyPeripherals = []
        nearbyPeripheralInfos = [CBPeripheral:BluetoothAdvertismentData]()
        if isScanInProgress {
            return
        }
        bluetoothManager.startScanPeripheral()
        isScanInProgress = true
    }
    func stopScanForPeripherals(){
        if isScanInProgress{
            bluetoothManager.stopScanPeripheral()
            isScanInProgress = false
        }
    }

    func connectWithLock(lockData:BluetoothAdvertismentData){
        
        //print("inside connectWithLock ==> step 2 ==>")
        //print(lockData)
        
        if  let peripheral = lockData.peripheral{
            bluetoothManager.connectPeripheral(peripheral)
        }
        else{
            // device not found
            //print("Device not found")
        }
    }

    func disconnectLock(){
        bluetoothManager.disconnectPeripheral()
    }

    func readCharacteristic(request:BLERequest){
        currentRequest = nil
        if lockService != nil{
            currentRequest = request
            print("request.characteristic ==>  \(request.characteristic)")
            let characteristicToRead = self.getCharacteristic(lockCharacteristic: request.characteristic)
            if characteristicToRead != nil {
                self.bluetoothManager.readValueForCharacteristic(characteristic: characteristicToRead!)
            }else{
                currentRequest?.completionBlock(false,nil,nil)
                print("request.characteristic ==> nil")
            }
        }
    }

    func write(data:Data,request:BLERequest)->Bool{
        currentRequest = nil
        if lockService != nil{
            currentRequest = request
            let characteristicToWrite = self.getCharacteristic(lockCharacteristic: request.characteristic)
            if characteristicToWrite == nil {
                //print("Writable characterisitc was nil")
                return false
            }
            self.bluetoothManager.setNotification(enable: true, forCharacteristic: characteristicToWrite!)
            self.bluetoothManager.writeValue(data: data, forCharacteristic: characteristicToWrite!, type: CBCharacteristicWriteType.withResponse)


            return true
        }
        return false
    }

    func getCharacteristic(lockCharacteristic:LockCharacteristic) -> CBCharacteristic?{
        let characteristics = lockService?.characteristics
        let filtered = characteristics?.first { $0.uuid.uuidString == lockCharacteristic.rawValue }
        print("filtered ====>>>>> \(filtered)")
        return filtered
    }

    func retrievePeripheral(uuidString uuid:String) -> CBPeripheral? {
        return BluetoothManager.getInstance().retrievePeripheral(uuidString:uuid)
    }


    @objc func didUpdateState(_ state: CBCentralManagerState){
        if state == .poweredOn {
            //self.scanForPeripherals()
        }
        else {
            self.stopScanForPeripherals()
        }
    }
    @objc func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        //print(advertisementData)
        if let string = advertisementData["kCBAdvDataLocalName"] as? String {
            //  let string = Data.parseRawDataToString(data: data)
            if string.contains(JsonUtils().getManufacturerCode()){
                if !nearbyPeripherals.contains(peripheral) {
                    var advertisment = BluetoothAdvertismentData()
                    advertisment.rssi = RSSI.intValue
                    advertisment.manufactureData = string
                    let localName = advertisementData["kCBAdvDataLocalName"] as! String
                    advertisment.localName = localName
                    advertisment.peripheral = peripheral
                    nearbyPeripheralInfos[peripheral] = advertisment
                    nearbyPeripherals.append(peripheral)
                    //print("nearbyperipheralinfos==\(nearbyPeripheralInfos)")
                    delegate?.didDiscoverNewLock(lockData: advertisment)
                }
                else{
                    var advertisement = nearbyPeripheralInfos[peripheral]
                    advertisement?.rssi = RSSI.intValue
                    nearbyPeripheralInfos[peripheral] = advertisement
                }
            }
            else{
                //unknown peripheral
            }
        }

    }
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("didConnectedPeripheral")
        connectedLock = connectedPeripheral
        self.bluetoothManager.discoverCharacteristics()
    }
    func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        print("didDisconnectPeripheral")
        connectedLock = nil
        self.delegate?.didDisconnectPeripheral()
    }
    func didDiscoverServices(_ peripheral: CBPeripheral) {
        bluetoothManager.discoverCharacteristics()
    }
    func didDiscoverCharacteritics(_ service: CBService) {
      print("didDiscoverCharacteritics")
        if service.uuid.uuidString == "00FF"{
            lockService = service
            delegate?.didFinishReadingAllCharacteristics()
        }
    }

    func didFailToDiscoverCharacteritics(_ error: Error) {
        print("didFailToDiscoverCharacteritics")
        connectedLock = nil
        currentRequest?.completionBlock(false,nil,nil)
        delegate?.didFailedToConnect(error: error.localizedDescription)
    }
    func didFailedToInterrogate(_ peripheral: CBPeripheral) {
        print("didFailedToInterrogate")
        connectedLock = nil
        delegate?.didFailedToConnect(error: "Device disconnected in the middle")
    }

    func didReadValueForCharacteristic(_ characteristic: CBCharacteristic) {
        print("didReadValueForCharacteristic")
        if characteristic.value != nil && characteristic.value!.count != 0 {
            let data = characteristic.value!
            let string = data.hexString()
            currentRequest?.completionBlock(true,string,nil)
        }

    }

    func didFailToReadValueForCharacteristic(_ error: Error) {
        print("didFailToReadValueForCharacteristic")
        currentRequest?.completionBlock(false,nil,error.localizedDescription)
        currentRequest = nil
    }

    func didWriteValueForForCharacteristic(_ characteristic: CBCharacteristic, _ error: Error?) {
        print("didWriteValueForForCharacteristic")
        if currentRequest != nil {
            let isSuccess = error == nil ? true: false
            let errorMessage = error?.localizedDescription
            currentRequest?.completionBlock(isSuccess, nil, errorMessage)
        }
    }
}



