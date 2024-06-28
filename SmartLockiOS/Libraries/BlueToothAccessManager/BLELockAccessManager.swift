//
//  BLELockAccessManager.swift
//  BluetoothAccess
//
//  Created by Dhilip on 6/17/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import Foundation

typealias BLEConnectionCompletion = (Bool) -> Void
enum LockCharacteristic: String {
    case lockStatus = "FF0D"
    case disengage = "FF0E"
    case ownerId = "FF01"
    case accessLogs = "FF07"
    case rewriteSlot = "FF12"
    case writeSlotKey = "FF02"
    case readSlotKey = "FF03"
    case activation = "FF0B"
    case writeStatus = "FF13"
    case authorization = "FF10"
    case date = "FF04"
    case time = "FF05"
    case revokeUser = "FF0C"
    case macAddress = "FF14"
    case batteryLevel = "FF15"
    case factoryReset = "FF16"
    case retrieveHardwareVersion = "FF17"
}
enum LockData: String {
    case ownerIdSlot0 = "00"
    case ownerIdSlot1 = "01"
    case disengage = "BB"
    case disableActivation = "00000000"
    case factoryResetData = "DD"
}
struct SlotKey {
    var slotId = ""
    var slotKey = ""
}
protocol BLELockConnectionProtocol:class {
    func didFailedToConnect(error: String)
    func didFinishReadingAllCharacteristics()
    func didPeripheralDisconnect()

}
protocol BLELockAccessDisengageProtocol:BLELockConnectionProtocol {
    func didFailAuthorization()
    func didFinishReadingAllCharacteristics()
    func didDisengageLock(isSuccess: Bool, error: String)
    func didCompleteOwnerTransfer(isSuccess: Bool, newOwnerId: String,oldOwnerId:String, error: String)
    func didReadBatteryLevel(batteryPercentage:String)
    func didReadAccessLogs(logs:String)
    func didCompleteDisengageFlow()
    func didCompleteFactoryReset(isSuccess : Bool, error: String)
    
}

protocol BLELockUserManagementProtocol:BLELockConnectionProtocol {
    func didRevokeUser(isSuccess: Bool,newKey:String,userId:String,error: String)
}

protocol BLELockAccessManagerDelegate:BLELockConnectionProtocol {
    func didActivateLock(isSuccess: Bool, error: String)
    func didCompleteReadingOwnerId()
    func didFailReadingOwnerId()
    func didCompleteReadingAllTheKeys()
    func didFailReadingAllTheKeys()
    func didDisactivateLock()
    func didFailDisactivation()
}

class BLELockAccessManager: BluetoothAccessManagerDelegate {
    weak var delegate: BLELockAccessManagerDelegate?
    weak var disengageDelegate: BLELockAccessDisengageProtocol?
    weak var userManagementDelegate:BLELockUserManagementProtocol?
    var scanController: BLEScanController = BLEScanController()
    static var shared:BLELockAccessManager = BLELockAccessManager()
    private var requestQueue = OperationQueue()
    var lockHardwareData: LockHardwareDetails = LockHardwareDetails()
    var operationArray: [BlockOperation] = []
    var operationIndex = -1
    var heartBeatTimer:Timer?
    var connectionCompletion:BLEConnectionCompletion?
    var transferOwnerNewId:String?
    
    var isAccessLogRead: Bool?

    init() {

    }
    func initialize() {
        DispatchQueue.global(qos: .background).async {[unowned self] in
            BluetoothAccessManager.shared.delegate = self
            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PeripheralNotificationKeys.DisconnectNotif.rawValue), object: self, queue: OperationQueue.main) {[unowned self] _ in
                self.peripheralDisconnected()
                self.delegate?.didPeripheralDisconnect()
            }

            BluetoothAccessManager.shared.initialize()
            self.scanController.initializeScanner()
        }
    }

    //MARK: BLE Advertisment Methods
    func checkForBluetoothAccess() -> BluetoothAccessState {
        return BluetoothAccessManager.shared.checkForBluetoothAccess()
    }
    func checkForLocationAccess() ->LocationAccessState {
        return BluetoothAccessManager.shared.checkForLocationAccess()
    }

    func scanForPeripherals() {
        scanController.scanForPeripherals()
    }

    func prolongedScanForPeripherals() {
        scanController.prolongedScanForPeripherals()
    }

    func stopPeripheralScan() {
        scanController.stopPeripheralScan()
    }
    //MARK: BLE Basic connection
    func connectWithLock(lockData: BluetoothAdvertismentData) {
        
        //print("inside connectWithLock ==> step 1 ==>")
        //print(lockData)
        
        lockHardwareData.lockAdvertisementData = lockData
        BluetoothAccessManager.shared.connectWithLock(lockData: lockData)
    }
    func connectWithLock(lockData: BluetoothAdvertismentData,completion:@escaping BLEConnectionCompletion) {
        if lockHardwareData.lockAdvertisementData?.peripheral == lockData.peripheral && lockData.peripheral?.state == .connected {
            completion(true)
            return
        }
        else{
            lockHardwareData.lockAdvertisementData = lockData
            BluetoothAccessManager.shared.connectWithLock(lockData: lockData)
            self.connectionCompletion = completion
        }
    }
    func disconnectLock(){
        BluetoothAccessManager.shared.disconnectLock()
        lockHardwareData = LockHardwareDetails()
        self.connectionCompletion = nil
    }

    func isLockConnected() -> Bool{
        if BluetoothAccessManager.shared.connectedLock == nil {
            return false
        }
        return BluetoothAccessManager.shared.connectedLock?.state == .connected
    }
    //MARK: BLE activation sequence
    func activateLock(scratchCode: String) {
        resetHardwareData()
        resetOperations()
        let data = scratchCode.toPlainData()
        let writeRequest = BLERequest(characteristic: .activation, isReadRequest: false) { [unowned self] isSuccess, response, error in
            if isSuccess == true {
                self.readOwnerId()
                self.delegate?.didActivateLock(isSuccess: true, error: "")
            }
            else {
                self.delegate?.didActivateLock(isSuccess: false, error: error!)
            }
        }
        /*
        let writeRequest = BLERequest(characteristic: .activation, isReadRequest: false) { [unowned self] isSuccess, _, _ in
            if isSuccess == true {
                self.readOwnerId()
                self.delegate?.didActivateLock(isSuccess: true, error: "")
            }
            else {
                self.delegate?.didActivateLock(isSuccess: false, error: "Activate lock failed")
            }
        }
        */
        
        let writeOperation = BlockOperation(block: {[unowned self] in
            //print("Writing scratch code")
            let writeStatus = BluetoothAccessManager.shared.write(data: data!, request: writeRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeOperation)
        queueExecuteNext()
    }

    func readOwnerId() {

        let slot1Data = LockData.ownerIdSlot0.rawValue.dataFromHexadecimalString()
        let slot2Data = LockData.ownerIdSlot1.rawValue.dataFromHexadecimalString()
        let request = readStatusOfWriteOperation { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                if response != nil && response?.isEmpty == false {
                    // Encrypt slot key value and then store in local
                    // While add lock isSecured should be true
                    let encryptedOwnerID = Utilities().convertStringToEncryptedString(plainString: response ?? "", isSecured: true)
                    self.lockHardwareData.lockOwnerIds.append(encryptedOwnerID)
                }
                if self.lockHardwareData.lockOwnerIds.count == 2 {
                    self.delegate?.didCompleteReadingOwnerId()
                    self.readAllTheSlotKeys()
                    
                }
                else {
                    self.queueExecuteNext()
                }
            }
            else {
                self.delegate?.didFailReadingOwnerId()
            }
        }

        let writeRequest = BLERequest(characteristic: .ownerId, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
                BluetoothAccessManager.shared.readCharacteristic(request: request)
            }
            else {
                self.delegate?.didFailReadingOwnerId()
            }
        }
        let writeOperation = BlockOperation(block: {[unowned self] in
            //print("Writing slot data 1")
            let writeStatus = BluetoothAccessManager.shared.write(data: slot1Data!, request: writeRequest)
            self.handle(write: writeStatus)
        })
        let writeOperation1 = BlockOperation(block: {[unowned self] in
            //print("Writing slot data 2 ")
            let writeStatus = BluetoothAccessManager.shared.write(data: slot2Data!, request: writeRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeOperation)
        operationArray.append(writeOperation1)
        queueExecuteNext()

    }

    func readAllTheSlotKeys() {
        resetOperations()
        let slotIdArray = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "0A", "0B", "0C", "0D", "0E", "0F", "11", "12", "13", "14", "15", "16", "17", "18"]
        for i in 0..<24 {
            let slotId = slotIdArray[i]
            let readRequest = BLERequest(characteristic: .readSlotKey, isReadRequest: true) { [unowned self] isSuccess, response, _ in
                //print("Reading response for \(slotId)")
                if isSuccess == true {
                    var slotIdAsString = ""
                    if i<10{
                     slotIdAsString = String("0\(i)")
                    }
                    else{
                        slotIdAsString = String("\(i)")
                    }
                    // Encrypt slot key value and then store in local
                    // Addlock isSecured for slot keys are always true
                    let encryptedSlotKey = Utilities().convertStringToEncryptedString(plainString: response ?? "", isSecured: true)
                    let slotKey = SlotKey(slotId: slotIdAsString, slotKey: encryptedSlotKey)
                    self.lockHardwareData.slotKeyArray.append(slotKey)
                    //print(response ?? "")
                    if (self.operationArray.count - 1) == self.operationIndex {
                        self.delegate?.didCompleteReadingAllTheKeys()
                        self.readMacAddress()
                    }
                    self.queueExecuteNext()
                }
            }
            let data = slotId.dataFromHexadecimalString()
            let request = BLERequest(characteristic: .writeSlotKey, isReadRequest: false) { isSuccess, response, _ in

                //print("writing response for \(slotId)")
                if isSuccess == true {
                    //print(response ?? "")
                    BluetoothAccessManager.shared.readCharacteristic(request: readRequest)
                }
            }
            let writeOperation = BlockOperation(block: {[unowned self] in
                //print("Writing \(slotId)")
                let writeStatus = BluetoothAccessManager.shared.write(data: data!, request: request)
                self.handle(write: writeStatus)
            })
            operationArray.append(writeOperation)
        }
        if operationArray.count > 0 {
            queueExecuteNext()
        }
        else {
            //print("completed reading")
            //resetActivationCode()
        }
    }

    func resetActivationCode() {
        if lockHardwareData.lockOwnerIds.count != 2 && lockHardwareData.slotKeyArray.count == 0 {
            return
        }

        let data = LockData.disableActivation.rawValue.toPlainData()
        let writeRequest = BLERequest(characteristic: .activation, isReadRequest: false) { [unowned self] isSuccess, _, _ in
            if isSuccess == true {
                //print("Lock disabled")
                //self.writeDateTime()
                self.delegate?.didDisactivateLock()
            }
            else {
                self.delegate?.didFailDisactivation()
            }
        }
        let writeOperation = BlockOperation(block: {[unowned self] in
            //print("disabling lock activation")
            let writeStatus = BluetoothAccessManager.shared.write(data: data!, request: writeRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeOperation)
        queueExecuteNext()
    }
    //MARK: BLE Lock
    func readMacAddress() {
        let request = BLERequest(characteristic: .macAddress, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                self.lockHardwareData.macAddress = String.hexToString(hex: response ?? "") ?? ""
//                self.resetActivationCode()
                self.readHardwareVersion()
            }
        }
        operationArray.append(BLEOperation.readOperation(request: request))
        self.queueExecuteNext()
    }

    // Read hardware version
    func readHardwareVersion() {
        let request = BLERequest(characteristic: .retrieveHardwareVersion, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                if (response != nil) {
                    self.lockHardwareData.lockVersion = String.hexToString(hex: response ?? "") ?? ""
                } else {
                    self.lockHardwareData.lockVersion = "v1.0"
                }
               self.resetActivationCode()
            } else {
                self.lockHardwareData.lockVersion = "v1.0"
                self.resetActivationCode()
            }
        }
        operationArray.append(BLEOperation.readOperation(request: request))
        self.queueExecuteNext()
    }
    
    func readBatteryLevel(key:String) {
        let batteryRequest = BLERequest(characteristic: .batteryLevel, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
                if response != nil {
                    let batteryLevel = String.hexToIntString(hexValue: response!) ?? ""
                    print("batteryLevel ==> \(batteryLevel)")
                    self.lockHardwareData.batteryLevel = batteryLevel
                    self.disengageDelegate?.didReadBatteryLevel(batteryPercentage: batteryLevel)
                }
                self.writeDateTime(key: key)
            } else {
                self.disengageDelegate?.didDisengageLock(isSuccess: false, error: "Failed to engage lock. Please press the lock button")
            }
        }
        operationArray.append(BLEOperation.readOperation(request: batteryRequest))
        self.queueExecuteNext()
    }
    
    func readLockStatus() {
        let request = BLERequest(characteristic: .lockStatus, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
            }
        }
        BluetoothAccessManager.shared.readCharacteristic(request: request)
    }
/*
    func readAccessLogs() {
        //authorizeUsingKey()
        let request = BLERequest(characteristic: .accessLogs, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print("access logs")
                //print(response ?? "")
                
                
                
                let string = String.hexToString(hex: response!) ?? ""
                
                //print("string ==> ")
                //print(string)
                
                if string.contains("00000000000") == false{
                    
                    // read more logs
                    self.readAccessLogs()
                    self.disengageDelegate?.didReadAccessLogs(logs: string)
                }
            }
            self.queueExecuteNext()
        }
        operationArray.append(BLEOperation.readOperation(request: request,operation: "access logs"))
    }
*/
    func authorizeUsingKey(_ authorizationKey:String) {
        //print("Authorizing using key \(authorizationKey)")
        let data = authorizationKey.dataFromHexadecimalString()
        let request = BLERequest(characteristic: .authorization, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("Authorization success")
                //print(response ?? "")
                self.queueExecuteNext()
            }
            else{
                //print("Authorization failed")
                self.disengageDelegate?.didFailAuthorization()
            }

        }
        let writeOperation = BLEOperation.writeOperation(data: data!, request: request)
        operationArray.append(writeOperation)
    }
    /*
    func disEngageLock(key: String) {
        authorizeUsingKey(key)

        let disengageData = LockData.disengage.rawValue.dataFromHexadecimalString()
        let disengageRequest = BLERequest(characteristic: .disengage, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            
            if isSuccess == true {
                //print(response ?? "")
                self.readBatteryLevel(key: key)
                self.readAccessLogs()
                self.writeDateTime()
                self.disengageDelegate?.didDisengageLock(isSuccess: true, error: "")
            }
            else{
                self.disengageDelegate?.didDisengageLock(isSuccess: false, error: "Failed to engage lock. Please press the lock button")
            }

        }
        let disengageWriteOperation = BlockOperation(block: {
            //print("writing disengage")
            let writeStatus = BluetoothAccessManager.shared.write(data: disengageData!, request: disengageRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(disengageWriteOperation)
        queueExecuteNext()
    }
    
    */

    func shouldWriteDateAndTime() -> Bool {
        let time = UserDefaults.standard.double(forKey: "last_set_date")
        if time == 0 {
            return true
        }
        else {
            let todayTime = Date.timeIntervalSinceReferenceDate
            // 10 days
            let differenceExpected = 24 * 60 * 60 * 10.0
            if (todayTime - time) > differenceExpected {
                return true
            }
            else {
                return false
            }
        }

    }
    /*
    func writeDateTime() {
        let dateData = Date().currentDateString().toPlainData()
        let writeDateRequest = BLERequest(characteristic: .date, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("date success")
                //print(response ?? "")
            }
            self.queueExecuteNext()
        }
        let writeDateOperation = BlockOperation(block: {
            //print("writing date")
            let writeStatus = BluetoothAccessManager.shared.write(data: dateData!, request: writeDateRequest)
            self.handle(write: writeStatus)
        })

        let timeData = Date().currentTimeString().toPlainData()
        let writeTimeRequest = BLERequest(characteristic: .time, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("time success")
                //print(response ?? "")
            }
            let time = Date.timeIntervalSinceReferenceDate
            UserDefaults.standard.set(time, forKey: "last_set_date")
            self.disengageDelegate?.didCompleteDisengageFlow()
        }
        let writeTimeOperation = BlockOperation(block: {[unowned self] in
            //print("writing time")
            let writeStatus = BluetoothAccessManager.shared.write(data: timeData!, request: writeTimeRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeDateOperation)
        operationArray.append(writeTimeOperation)
        queueExecuteNext()
    }
    */
    /*
    func readAccessLogsTransferOwnerFlow() {
        //authorizeUsingKey()
        let request = BLERequest(characteristic: .accessLogs, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print("access logs")
                //print(response ?? "")
                
                
                
                let string = String.hexToString(hex: response!) ?? ""
                
                //print("string ==> ")
                //print(string)
                
                if string.contains("00000000000") == false{
                    
                    // read more logs
                    self.readAccessLogs(key: <#String#>)
                    self.disengageDelegate?.didReadAccessLogs(logs: string)
                    self.disengageDelegate?.didCompleteDisengageFlow()

                }
            }
            self.queueExecuteNext()
        }
        operationArray.append(BLEOperation.readOperation(request: request,operation: "access logs"))
    }
    */
    
    func writeDateTimeTransferOwnerFlow() {
//        let dateData = Date().currentDateString().toPlainData()
        let dateD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[0])\0"
        let dateData = dateD.toPlainData()

        let writeDateRequest = BLERequest(characteristic: .date, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("date success")
                //print(response ?? "")
            }
            self.queueExecuteNext()
        }
        let writeDateOperation = BlockOperation(block: {
            //print("writing date")
            let writeStatus = BluetoothAccessManager.shared.write(data: dateData!, request: writeDateRequest)
            self.handle(write: writeStatus)
        })
        
//        let timeData = Date().currentTimeString().toPlainData()
        let timeD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[1])\0"
        let timeData = timeD.toPlainData()

        let writeTimeRequest = BLERequest(characteristic: .time, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("time success")
                //print(response ?? "")
            }
            let time = Date.timeIntervalSinceReferenceDate
            UserDefaults.standard.set(time, forKey: "last_set_date")
        }
        let writeTimeOperation = BlockOperation(block: {[unowned self] in
            //print("writing time")
            let writeStatus = BluetoothAccessManager.shared.write(data: timeData!, request: writeTimeRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeDateOperation)
        operationArray.append(writeTimeOperation)
        queueExecuteNext()
    }
    
    
    func factoryReset(userKey:String) {
        authorizeUsingKey(userKey)
        let factoryResetData = LockData.factoryResetData.rawValue.dataFromHexadecimalString()
        let writeFRRequest = BLERequest(characteristic: .factoryReset, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("writeFRRequest  success")
                //print(response ?? "")
                self.disengageDelegate?.didCompleteFactoryReset(isSuccess: true, error: "")
            }
            else
            {
                self.disengageDelegate?.didCompleteFactoryReset(isSuccess: false, error: "Factory reset failure")
            }
            //self.queueExecuteNext()
        }
        let writeFROperation = BLEOperation.writeOperation(data: factoryResetData!, request: writeFRRequest)
        operationArray.append(writeFROperation)
        queueExecuteNext()
    }
    func revokeUserKey(slotNumber: String,userKey:String, userId:String) {
        authorizeUsingKey(userKey)
        let slotNumberAsInteger = Int(slotNumber)
        let slotIdAsString = String(format:"%02X", slotNumberAsInteger!)
        if let slotNumberData = slotIdAsString.dataFromHexadecimalString() {
            let writeSlotNumberRequest = BLERequest(characteristic: .revokeUser, isReadRequest: false) { [unowned self] isSuccess, response, _ in
                if isSuccess == true {
                    //print(response ?? "")
                    self.queueExecuteNext()
                }
                else{
                    self.userManagementDelegate?.didRevokeUser(isSuccess: false, newKey: "", userId: userId, error: "Unknown error")
                }
            }
            let writeSlotNumberOperation = BLEOperation.writeOperation(data: slotNumberData, request: writeSlotNumberRequest,operation: "Write slot number")
            operationArray.append(writeSlotNumberOperation)

            let writeToNewKeyRequest = BLERequest(characteristic: .writeSlotKey, isReadRequest: false) { [unowned self] isSuccess, response, _ in
                if isSuccess == true {
                    //print(response ?? "")

                }
                else{
                    self.userManagementDelegate?.didRevokeUser(isSuccess: false, newKey: "", userId: userId, error: "Unknown error")
                }
                self.queueExecuteNext()
            }
            let writeToNewKeyOperation = BLEOperation.writeOperation(data: slotNumberData, request: writeToNewKeyRequest,operation: "Write new key")
            operationArray.append(writeToNewKeyOperation)

            let readNewKeyRequest = BLERequest(characteristic: .readSlotKey, isReadRequest: true) { [unowned self] isSuccess, response, _ in
                if isSuccess == true {
                    //print(response ?? "")
                    self.userManagementDelegate?.didRevokeUser(isSuccess: true, newKey: response ?? "", userId: userId, error: "")
                }
                else{
                    self.userManagementDelegate?.didRevokeUser(isSuccess: false, newKey: "", userId: userId, error: "Unknown error")

                }
                self.queueExecuteNext()
            }
            let readNewKeyOperation = BLEOperation.readOperation(request: readNewKeyRequest,operation: "read new key")
            operationArray.append(readNewKeyOperation)
            self.queueExecuteNext()
        }
        else{
            self.userManagementDelegate?.didRevokeUser(isSuccess: false, newKey: "", userId: userId, error: "Unknown error")
        }
    }


    func transferOwnership(slotNumber:String,key:String,oldOwnerId:String){
        //print("Authorizing using key \(key)")
        let data = key.dataFromHexadecimalString()
        let request = BLERequest(characteristic: .authorization, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("Authorization success")
                //print(response ?? "")
                self.readWriteTransferOwnerSlotKey(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
            } else {
                //print("Authorization failed")
                self.disengageDelegate?.didFailAuthorization()
            }
        }
        let authorizationWriteOperation = BLEOperation.writeOperation(data: data!, request: request)
        operationArray.append(authorizationWriteOperation)
        self.queueExecuteNext()
    }
    
    func readWriteTransferOwnerSlotKey(slotNumber:String,key:String,oldOwnerId:String) {
        var slot2Data = LockData.ownerIdSlot1.rawValue.dataFromHexadecimalString()
        if slotNumber == "01"{
            slot2Data = LockData.ownerIdSlot0.rawValue.dataFromHexadecimalString()
        }
        
        let writeRequest = BLERequest(characteristic: .ownerId, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
                
                let readRequest = self.readStatusOfWriteOperation { [unowned self] isSuccess, response, _ in
                    if isSuccess == true {
                        if response != nil && response?.isEmpty == false {
                            self.transferOwnerNewId = response
                        }
                        
                    } else {
                        self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
                    }
                    self.readBatteryLevelForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
                }

                BluetoothAccessManager.shared.readCharacteristic(request: readRequest)
            }
            else {
                self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
            }
            //self.queueExecuteNext()
        }
        let writeOperation = BLEOperation.writeOperation(data: slot2Data!, request: writeRequest, operation: "Write Owner Id")
        operationArray.append(writeOperation)
        self.queueExecuteNext()

    }
    
    func readBatteryLevelForFirstEngage(slotNumber:String,key:String,oldOwnerId:String) {
        let batteryRequest = BLERequest(characteristic: .batteryLevel, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
                if response != nil {
                    let batteryLevel = String.hexToIntString(hexValue: response!) ?? ""
                    //print("batteryLevel ==> \(batteryLevel)")
                    self.lockHardwareData.batteryLevel = batteryLevel
                    self.disengageDelegate?.didReadBatteryLevel(batteryPercentage: batteryLevel)
                }
                self.writeDateTimeForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
            } else {
                self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
            }
        }
        operationArray.append(BLEOperation.readOperation(request: batteryRequest))
        self.queueExecuteNext()
    }
    
    func writeDateTimeForFirstEngage(slotNumber:String,key:String,oldOwnerId:String) {
//        let dateData = Date().currentDateString().toPlainData()
        let date = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[0])\0"
        let dateData = date.toPlainData()
                
        let writeDateRequest = BLERequest(characteristic: .date, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("date success")
                self.writeTimeOperationForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
            } else {
                self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
            }
        }
        let writeDateOperation = BlockOperation(block: {
            //print("writing date")
            let writeStatus = BluetoothAccessManager.shared.write(data: dateData!, request: writeDateRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeDateOperation)
        queueExecuteNext()
    }
    
    func writeTimeOperationForFirstEngage(slotNumber:String,key:String,oldOwnerId:String) {
//        let timeData = Date().currentTimeString().toPlainData()
        let timeD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[1])\0"
        let timeData = timeD.toPlainData()

        print(Date().currentTimeString())
        let writeTimeRequest = BLERequest(characteristic: .time, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("time success")
                
                self.isAccessLogRead = false
                self.readAccessLogsForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
                
            } else {
                self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
            }
            //            let time = Date.timeIntervalSinceReferenceDate
            //            UserDefaults.standard.set(time, forKey: "last_set_date")
        }
        let writeTimeOperation = BlockOperation(block: {[unowned self] in
            //print("writing time")
            let writeStatus = BluetoothAccessManager.shared.write(data: timeData!, request: writeTimeRequest)
            self.handle(write: writeStatus)
        })
        self.operationArray.append(writeTimeOperation)
        self.queueExecuteNext()
    }
    
    func disEngageFirstTimeEngageWith(slotNumber:String,key:String,oldOwnerId:String) {
        let disengageData = LockData.disengage.rawValue.dataFromHexadecimalString()
        let disengageRequest = BLERequest(characteristic: .disengage, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "")
                self.isAccessLogRead = true
                self.readAccessLogsForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
            } else {
                self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: false,newOwnerId: "", oldOwnerId: oldOwnerId ,error: "Transfer owner failed")
            }
            self.queueExecuteNext()
        }
        let disengageWriteOperation = BlockOperation(block: {[unowned self] in
            //print("writing disengage")
            let writeStatus = BluetoothAccessManager.shared.write(data: disengageData!, request: disengageRequest)
            self.handle(write: writeStatus)
            
        })
        operationArray.append(disengageWriteOperation)
        self.queueExecuteNext()

    }
    
    func readAccessLogsForFirstEngage(slotNumber:String,key:String,oldOwnerId:String) {
        //authorizeUsingKey()
        
        let request = BLERequest(characteristic: .accessLogs, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "log test")
                let string = String.hexToString(hex: response!) ?? ""
                //print("string ==> ")
                //print(string)
                if string.contains("00000000000") == false && string.contains("303030303030303030303030303030303030303030") == false {
                    // read more logs
                    self.readAccessLogsForFirstEngage(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
                    self.disengageDelegate?.didReadAccessLogs(logs: string)
                } else {
                    
//                    self.disengageDelegate?.didCompleteDisengageFlow()
                    if self.isAccessLogRead == true {
                        self.disengageDelegate?.didCompleteOwnerTransfer(isSuccess: true,newOwnerId: self.transferOwnerNewId!, oldOwnerId: oldOwnerId ,error: "")
                    } else {
                        self.disEngageFirstTimeEngageWith(slotNumber: slotNumber, key: key, oldOwnerId: oldOwnerId)
                    }
                }
            }
        }
        operationArray.append(BLEOperation.readOperation(request: request,operation: "access logs"))
        self.queueExecuteNext()
        
    }
    

    func didDiscoverNewLock(lockData: BluetoothAdvertismentData) {
        scanController.didDiscoverNewLock(lockData: lockData)
    }

    func didFailedToConnect(error: String) {
        delegate?.didFailedToConnect(error: error)
        self.connectionCompletion?(false)
    }
    func didDisconnectPeripheral() {
        self.peripheralDisconnected()
        self.delegate?.didPeripheralDisconnect()
        self.connectionCompletion?(false)
        self.connectionCompletion = nil
    }

    func didFinishReadingAllCharacteristics() {
        DispatchQueue.main.async {[unowned self] in
            self.delegate?.didFinishReadingAllCharacteristics()
            self.disengageDelegate?.didFinishReadingAllCharacteristics()
            self.connectionCompletion?(true)
        }

    }

    func readStatusOfWriteOperation(completionBlock: @escaping BLERequestCompletionBlock) -> BLERequest {
        let readRequest = BLERequest(characteristic: .writeStatus, isReadRequest: true, completion: completionBlock)
        return readRequest
    }

    func addReadStatusOfWriteOperation() {
        let readRequest = BLERequest(characteristic: .writeStatus, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print("Write operation status")
                //print(response ?? "")
            }
        }
        let readOperation = BlockOperation(block: {
            //print("reading Write operation status")
            BluetoothAccessManager.shared.readCharacteristic(request: readRequest)
        })
        operationArray.append(readOperation)
        queueExecuteNext()
    }

    func resetHardwareData(){
        let bleAdvertisementData = lockHardwareData.lockAdvertisementData
        lockHardwareData = LockHardwareDetails()
        lockHardwareData.lockAdvertisementData = bleAdvertisementData
    }
    
    // MARK: - Try
    
    func disEngageLock(key: String) {
        //print("Authorizing using key \(key)")
        let data = key.dataFromHexadecimalString()
        let request = BLERequest(characteristic: .authorization, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("Authorization success")
                //print(response ?? "")
                self.readBatteryLevel(key: key)
            } else {
                //print("Authorization failed")
                self.disengageDelegate?.didFailAuthorization()
            }
        }
        if let dataValue = data{
        let authorizationWriteOperation = BLEOperation.writeOperation(data: dataValue, request: request)
        operationArray.append(authorizationWriteOperation)
        self.queueExecuteNext()
        }
    }
    
    func disEngageWith(key: String) {
        
        let disengageData = LockData.disengage.rawValue.dataFromHexadecimalString()
        let disengageRequest = BLERequest(characteristic: .disengage, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            
            if isSuccess == true {
                //print(response ?? "Engage success")
                self.isAccessLogRead = true
                self.readAccessLogs(key: key)
                
            } else {
                self.disengageDelegate?.didDisengageLock(isSuccess: false, error: "Failed to engage lock. Please press the lock button")
            }
            
        }
        let disengageWriteOperation = BlockOperation(block: {
            //print("writing disengage")
            let writeStatus = BluetoothAccessManager.shared.write(data: disengageData!, request: disengageRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(disengageWriteOperation)
        queueExecuteNext()

    }
    
    
    func readAccessLogs(key: String) {
        //authorizeUsingKey()
        
        let request = BLERequest(characteristic: .accessLogs, isReadRequest: true) { isSuccess, response, _ in
            if isSuccess == true {
                //print(response ?? "log test")
                let string = String.hexToString(hex: response!) ?? ""
                
                if string.contains("00000000000") == false && string.contains("303030303030303030303030303030303030303030") == false {
                    // read more logs
                    self.readAccessLogs(key: key)
                    self.disengageDelegate?.didReadAccessLogs(logs: string)
                } else {
                    
                    if self.isAccessLogRead == false {
                        //print("disEngageWith ==> **********")
                        self.disEngageWith(key: key)
                    } else {
                        //print("didCompleteDisengageFlow ==> **********")

                        self.disengageDelegate?.didCompleteDisengageFlow()
                        self.disengageDelegate?.didDisengageLock(isSuccess: true, error: "")
                    }
                }
            }
        }
        operationArray.append(BLEOperation.readOperation(request: request,operation: "access logs"))
        self.queueExecuteNext()

    }
    
    func writeDateTime(key: String) {
//        let dateData = Date().currentDateString().toPlainData()
        let dateD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[0])\0"
        let dateData = dateD.toPlainData()

        let writeDateRequest = BLERequest(characteristic: .date, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("date success")
                self.writeTimeOperation(key: key)
            } else {
                self.disengageDelegate?.didDisengageLock(isSuccess: false, error: "Failed to engage lock. Please press the lock button")
            }
        }
        let writeDateOperation = BlockOperation(block: {
            //print("writing date")
            let writeStatus = BluetoothAccessManager.shared.write(data: dateData!, request: writeDateRequest)
            self.handle(write: writeStatus)
        })
        operationArray.append(writeDateOperation)
        queueExecuteNext()
    }
    
    func writeTimeOperation(key: String) {
//        let timeData = Date().currentTimeString().toPlainData()
        let timeD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[1])\0"
        let timeData = timeD.toPlainData()


        let writeTimeRequest = BLERequest(characteristic: .time, isReadRequest: false) { [unowned self] isSuccess, response, _ in
            if isSuccess == true {
                //print("time success")
                self.isAccessLogRead = false
                self.readAccessLogs(key: key)
            } else {
                self.disengageDelegate?.didDisengageLock(isSuccess: false, error: "Failed to engage lock. Please press the lock button")
            }
//            let time = Date.timeIntervalSinceReferenceDate
//            UserDefaults.standard.set(time, forKey: "last_set_date")
        }
        let writeTimeOperation = BlockOperation(block: {[unowned self] in
            //print("writing time")
            let writeStatus = BluetoothAccessManager.shared.write(data: timeData!, request: writeTimeRequest)
            self.handle(write: writeStatus)
        })
        self.operationArray.append(writeTimeOperation)
        self.queueExecuteNext()
    }

}

// MARK: - BLELockAccessManager methods
extension BLELockAccessManager {
    //MARK: BLE Queue Operations
    func initializeOperationQueue() {
        requestQueue.maxConcurrentOperationCount = 1
    }
    func addOperation() {
        let operation = operationArray[operationIndex]
        requestQueue.addOperation(operation)
    }

    func queueExecuteNext() {

        if operationIndex < (operationArray.count - 1) {
            operationIndex = operationIndex + 1
            addOperation()
        }
        else {
            //print("finished operations")
            operationArray.removeAll()
            operationIndex = -1
        }
    }

    func resetOperations() {
        operationArray.removeAll()
        operationIndex = -1
    }

    func peripheralDisconnected() {
        resetOperations()
    }
}
extension BLELockAccessManager {
    func handle(write status:Bool){
        if status == false {
            Utilities.showErrorAlertView(message: "Please switch to WiFi or try again", presenter: nil)
            disconnectLock()
        }
    }
}
