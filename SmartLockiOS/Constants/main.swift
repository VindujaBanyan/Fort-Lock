//
//  main.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 19/11/18.
//  Copyright © 2018 payoda. All rights reserved.
//

//import Foundation
//import UIKit
//
//UIApplicationMain(
//    CommandLine.argc,
//    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
//        .bindMemory(
//            to: UnsafeMutablePointer<Int8>.self,
//            capacity: Int(CommandLine.argc)),
//    NSStringFromClass(TimerApplication.self),
//    NSStringFromClass(AppDelegate.self)
//)
import UIKit
import Foundation
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    NSStringFromClass(TimerApplication.self),
    NSStringFromClass(AppDelegate.self)
//UIApplicationMain(
//    CommandLine.argc,
//    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
//        .bindMemory(
//            to: UnsafeMutablePointer<Int8>.self,
//            capacity: Int(CommandLine.argc)),
//    NSStringFromClass(TimerApplication.self),
//    NSStringFromClass(AppDelegate.self)
)

