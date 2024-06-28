//
//  CITreeViewData.swift
//  CITreeView
//
//  Created by Apple on 24.01.2018.
//  Copyright © 2018 Cenk Işık. All rights reserved.
//

import UIKit

class CITreeViewData {
    
    let name : String
    let slotNumber: String
    var children : [CITreeViewData]
    
    init(name : String, children: [CITreeViewData] = [CITreeViewData](), slotNumber: String) {
        self.name = name
        self.children = children
        self.slotNumber = slotNumber
    }
    
    /*convenience init(name : String) {
        self.init(name: name, children: [CITreeViewData]())
    }*/
    
    func addChild(_ child : CITreeViewData) {
        self.children.append(child)
    }
    
    func removeChild(_ child : CITreeViewData) {
        self.children = self.children.filter( {$0 !== child})
    }
}

extension CITreeViewData {
    /*
    static func getDefaultCITreeViewData() -> [CITreeViewData] {
        
        let subChild121 = CITreeViewData(name: "Albea")
        let subChild122 = CITreeViewData(name: "Egea")
        let subChild123 = CITreeViewData(name: "Linea")
        let subChild124 = CITreeViewData(name: "Siena")
        
        let child11 = CITreeViewData(name: "Volvo")
        let child12 = CITreeViewData(name: "Fiat", children:[subChild121, subChild122, subChild123, subChild124])
        let child13 = CITreeViewData(name: "Alfa Romeo")
        let child14 = CITreeViewData(name: "Mercedes")
        let parent1 = CITreeViewData(name: "Sedan", children: [child11, child12, child13, child14])
        
        let subChild221 = CITreeViewData(name: "Discovery")
        let subChild222 = CITreeViewData(name: "Evoque")
        let subChild223 = CITreeViewData(name: "Defender")
        let subChild224 = CITreeViewData(name: "Freelander")
        
        let child21 = CITreeViewData(name: "GMC")
        let child22 = CITreeViewData(name: "Land Rover" , children: [subChild221,subChild222,subChild223,subChild224])
        let parent2 = CITreeViewData(name: "SUV", children: [child21, child22])
        
        
        let child31 = CITreeViewData(name: "Wolkswagen")
        let child32 = CITreeViewData(name: "Toyota")
        let child33 = CITreeViewData(name: "Dodge")
        let parent3 = CITreeViewData(name: "Truck", children: [child31, child32,child33])
        
        let subChildChild5321 = CITreeViewData(name: "Carrera", children: [child31, child32,child33])
        let subChildChild5322 = CITreeViewData(name: "Carrera 4 GTS")
        let subChildChild5323 = CITreeViewData(name: "Targa 4")
        let subChildChild5324 = CITreeViewData(name: "Turbo S")
        
        let parent4 = CITreeViewData(name: "Van",children:[subChildChild5321,subChildChild5322,subChildChild5323,subChildChild5324])
        
       
        
        let subChild531 = CITreeViewData(name: "Cayman")
        let subChild532 = CITreeViewData(name: "911",children:[subChildChild5321,subChildChild5322,subChildChild5323,subChildChild5324])
        
        let child51 = CITreeViewData(name: "Renault")
        let child52 = CITreeViewData(name: "Ferrari")
        let child53 = CITreeViewData(name: "Porshe", children: [subChild531, subChild532])
        let child54 = CITreeViewData(name: "Maserati")
        let child55 = CITreeViewData(name: "Bugatti")
        let parent5 = CITreeViewData(name: "Sports Car",children:[child51,child52,child53,child54,child55])

        
        return [parent5,parent2,parent1,parent3,parent4]
    }
    */
    
    
    static func getDefaultCITreeViewData(dataArray: [[AssignUserModel]]) -> [CITreeViewData] {
        
        
        var masterTreeData = [CITreeViewData]()
        var ownerUserTreeData = [CITreeViewData]()
        
        var generalUserTreeData = [CITreeViewData]()

        if dataArray.count > 0 {
            
            let levelOneArray = dataArray[0] as [AssignUserModel]
            
            var masterOneTreeData = [CITreeViewData]()
            var masterTwoTreeData = [CITreeViewData]()
            var masterThreeTreeData = [CITreeViewData]()

            let levelOneUserArray = dataArray[4] as [AssignUserModel]
            if levelOneUserArray.count > 0 {
                for userObj in levelOneUserArray {
                    //print(userObj.slotNumber)
                    ownerUserTreeData.append(CITreeViewData(name: userObj.name, slotNumber: userObj.slotNumber))
                }
            }
            var masterOneDataArray = dataArray[1] as [AssignUserModel]
            var masterTwoDataArray = dataArray[2] as [AssignUserModel]
            var masterThreeDataArray = dataArray[3] as [AssignUserModel]

            if masterOneDataArray.count > 0 {
                for i in 0..<masterOneDataArray.count {
                    
                    let userObj = masterOneDataArray[i]
                    masterOneTreeData.append(CITreeViewData(name: userObj.name, slotNumber: userObj.slotNumber))
                }
            }
            
            if masterTwoDataArray.count > 0 {
                for i in 0..<masterTwoDataArray.count {
                    
                    let userObj = masterTwoDataArray[i]
                    masterTwoTreeData.append(CITreeViewData(name: userObj.name, slotNumber: userObj.slotNumber))
                }
            }
            
            if masterThreeDataArray.count > 0 {
                for i in 0..<masterThreeDataArray.count {
                    
                    let userObj = masterThreeDataArray[i]
                    masterThreeTreeData.append(CITreeViewData(name: userObj.name, slotNumber: userObj.slotNumber))
                }
            }
            
            if levelOneArray.count > 0 { // Master
                
                var masterUsersDataArray = [[CITreeViewData]]()
                masterUsersDataArray.append(masterOneTreeData)
                masterUsersDataArray.append(masterTwoTreeData)
                masterUsersDataArray.append(masterThreeTreeData)
                
                for i in 0..<levelOneArray.count {
                    
                    let masterObj = levelOneArray[i]
                    masterTreeData.append(CITreeViewData(name: masterObj.name, children: masterUsersDataArray[i], slotNumber: masterObj.slotNumber))
                }
                
                let parent1 = CITreeViewData(name: "MASTER USER(S)", children: masterTreeData, slotNumber: "")
                let parent2 = CITreeViewData(name: "GENERAL USER(S)", children: ownerUserTreeData, slotNumber: "")

                return [parent1,parent2]

            } else {
                
                
                
                if ownerUserTreeData.count > 0 {
                    generalUserTreeData = ownerUserTreeData
                } else {
                    if masterOneTreeData.count > 0 {
                        generalUserTreeData = masterOneTreeData
                    } else {
                        if masterTwoTreeData.count > 0 {
                            generalUserTreeData = masterTwoTreeData
                        } else {
                            if masterThreeTreeData.count > 0 {
                                generalUserTreeData = masterThreeTreeData
                            } else {
                                
                            }
                        }
                    }
                }
                                
                let parent1 = CITreeViewData(name: "GENERAL USER(S)", children: generalUserTreeData, slotNumber: "")
                return [parent1]

            }
        } else {
            return []
        }        
    }
    
}
