//
//  CoreDataController.swift
//  SmartLockiOS
//
//  Created by Kishore Prabhu Radhakrishnan on 08/04/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
import CoreData


class CoreDataController: NSObject {

    var decodeObj = DecodeDataClass()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var entity = "LockListEntity"
    
    var coreDataArray = [LockListModel]()
    
    
    func saveLock(lockobject:LockListModel){
        
        let appelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appelegate?.persistentContainer.viewContext
        
      //Encode values
        
        let lockOwner_as_String =   decodeObj.encodeLockOwnerToJson(param: lockobject.lock_owner_id)
        let userRole_as_String = decodeObj.encodeUserRoleToJson(param: lockobject.lock_keys)
        
    
        
      

        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "serial_number = %@", lockobject.serial_number)
        
        do{
            let results = try context?.fetch(fetchRequest) as? [NSManagedObject]
            if results != nil && results?.count != 0 {
                // update
                let managedObject = results?[0]
                managedObject?.setValue(lockobject.id, forKey: "id")
                managedObject?.setValue(lockobject.lockname, forKey: "lockname")
                managedObject?.setValue(userRole_as_String, forKey: "lock_keys")
                managedObject?.setValue(lockobject.scratch_code, forKey: "scratch_code")
                managedObject?.setValue(lockobject.serial_number, forKey: "serial_number")
                managedObject?.setValue(lockobject.uuid, forKey: "uuid")
                managedObject?.setValue(lockobject.ssid, forKey: "ssid")
                managedObject?.setValue(lockobject.status, forKey: "status")
                managedObject?.setValue(lockOwner_as_String, forKey: "lock_owner_id")
                managedObject?.setValue(false, forKey: "wasAddedOffline")
                managedObject?.setValue(lockobject.battery, forKey: "battery")
                managedObject?.setValue(lockobject.lockVersion, forKey: "lockVersion")
                managedObject?.setValue(lockobject.is_secured, forKey: "is_secured")
                managedObject?.setValue(lockobject.userPrivileges, forKey: "userPrivileges")
                managedObject?.setValue(lockobject.enable_fp, forKey: "enable_fp")
                managedObject?.setValue(lockobject.enable_pin, forKey: "enable_pin")
                try context?.save()
                print("replace ")
            }else{
                //save
                do{
                    // set NSManagedObject
                    let lock = NSEntityDescription.insertNewObject(forEntityName: entity, into: context!)
                      //set values
                      lock.setValue(lockobject.id, forKey: "id")
                      lock.setValue(lockobject.lockname, forKey: "lockname")
                      lock.setValue(userRole_as_String, forKey: "lock_keys")
                      lock.setValue(lockobject.scratch_code, forKey: "scratch_code")
                      lock.setValue(lockobject.serial_number, forKey: "serial_number")
                      lock.setValue(lockobject.uuid, forKey: "uuid")
                      lock.setValue(lockobject.ssid, forKey: "ssid")
                      lock.setValue(lockobject.status, forKey: "status")
                      lock.setValue(lockOwner_as_String, forKey: "lock_owner_id")
                      lock.setValue(false, forKey: "wasAddedOffline")
                      lock.setValue(lockobject.battery, forKey: "battery")
                      lock.setValue(lockobject.lockVersion, forKey: "lockVersion")
                      lock.setValue(lockobject.is_secured, forKey: "is_secured")
                      lock.setValue(lockobject.userPrivileges, forKey: "userPrivileges")
                      lock.setValue(lockobject.enable_fp, forKey: "enable_fp")
                      lock.setValue(lockobject.enable_pin, forKey: "enable_pin")
                    try context?.save()
                    print("saved ")
                }
                catch{
                    print("error: didn't save")
                }
            }
            
        }
        catch{
            print(" error in fetch")
            
         }
        
    }
    
    
    func fetchLockList()-> [LockListModel]{
        
        
    let appelegate = UIApplication.shared.delegate as? AppDelegate
    let managedContext = appelegate?.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        
        
    request.returnsObjectsAsFaults = false
        
    
    do{
        let results = try managedContext?.fetch(request)
        
        print("Resultscount001 = \(String(describing: results?.count))")
        
        
        coreDataArray.removeAll()
        
        if results != nil{
            
            
            coreDataArray = appendToArray(fetchResult: results!)
           
            print("coreDataArray.count = \(coreDataArray.count)")
            
            
        }
        
    }
    catch{
        print(" error in fetch")
        
     }

    print("coreData== \(coreDataArray.count)")
    return coreDataArray
    
    }
    

    
    func updateLockList(id:String, updateKey:String, updateValue:String){
        
        let appelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appelegate?.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
        let pred = NSPredicate(format:"id=\(id)")
        request.predicate = pred
        
        do{
//        fetchLockList()
        let edit  = try context?.fetch(request)
        
        if edit!.count > 0{
            let objectUpdate = edit![0] as! NSManagedObject
            objectUpdate.setValue(updateValue, forKey: updateKey)
        }
        
        do{
            try context?.save()
            print("update success")
        }
        
         catch{
            print("update error")
         }
        }
        catch{
            
            print("fetch error ")
        }
        
        
    }
    
    
    func deleteLockList(id:String){
        
        
        let appelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appelegate?.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
        let pred = NSPredicate(format:"id=\(id)")
        request.predicate = pred
        
        do{
        //fetchLockList()
        let edit  = try context?.fetch(request)
        
        if edit!.count > 0{
            let objectDelete = edit![0] as! NSManagedObject
            context?.delete(objectDelete)
            
        }
        
        do{
            try context?.save()
            print("update success")
        }
        
         catch{
            print("update error")
         }
        }
        catch{
            
            print("fetch error ")
        }
        
        
    }
    
    func deleteAllData(){
        let appelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appelegate?.persistentContainer.viewContext
        let ReqVar = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: ReqVar)
        do { try context!.execute(DelAllReqVar) }
        catch { print(error) }
    }
    
    
    func appendToArray(fetchResult:[Any])->[LockListModel]{
        
        var data = [LockListModel]()
        
        for i in fetchResult as! [NSManagedObject]{
         
    
           // print("id=\(String(describing: i.value(forKey: "id"))) ::: \(String(describing: i.value(forKey: "lockname")))")
            
            //create object
            let lockListObj = LockListModel(json: [:])
            
            //convert pushed String as object
            let userRole_decode = decodeObj.decodeUserRole(jsonData: i.value(forKey: "lock_keys") as! String)
            
            let lockOwner_decode = decodeObj.decodeLockOwner(jsonData: i.value(forKey: "lock_owner_id") as! String)
            
            
          //assign fetched values to object value
            lockListObj.lock_owner_id = lockOwner_decode
            lockListObj.lock_keys = userRole_decode
            
            lockListObj.id = (i.value(forKey: "id") as? String)
            lockListObj.lockname = (i.value(forKey: "lockname") as! String)
            lockListObj.scratch_code = (i.value(forKey: "scratch_code") as! String)
            lockListObj.serial_number = (i.value(forKey: "serial_number") as! String)
            lockListObj.uuid = (i.value(forKey: "uuid") as! String)
            lockListObj.ssid = ""
            lockListObj.status = ""
            lockListObj.wasAddedOffline = false
            lockListObj.battery = i.value(forKey: "battery") as! String
            lockListObj.lockVersion = (i.value(forKey: "lockVersion") as? String)
            lockListObj.is_secured = (i.value(forKey: "is_secured")) as! String
            lockListObj.userPrivileges = (i.value(forKey: "userPrivileges") as! String)
            lockListObj.enable_fp = (i.value(forKey: "enable_fp") as? String)
            lockListObj.enable_pin = (i.value(forKey: "enable_pin") as? String)



            data.append(lockListObj)
        
          

            
        }
        return data
        
    }
    
    
    
    
}
