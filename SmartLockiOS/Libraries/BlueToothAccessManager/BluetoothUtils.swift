//
//  BluetoothUtils.swift
//  BluetoothAccess
//
//  Created by Dhilip on 6/17/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import Foundation
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        let hexString = map { String(format: format, $0) }.joined()
        return hexToString(hex: hexString) ?? ""
    }
    
    func hexEncodedStringNew(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }

    func hexToString(hex: String) -> String? {
        guard hex.count % 2 == 0 else {
            return nil
        }

        var bytes = [CChar]()

        var startIndex = hex.index(hex.startIndex, offsetBy: 0)
        while startIndex < hex.endIndex {
            let endIndex = hex.index(startIndex, offsetBy: 2)
            let substr = hex[startIndex..<endIndex]

            if let byte = Int8(substr, radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }

            startIndex = endIndex
        }

        bytes.append(0)
        return String(cString: bytes)
    }

    static func parseRawDataToString(data:Data) -> String{
        var bytes = [UInt8](data)
        bytes.remove(at: 0)
        bytes.remove(at: 0)
        let nsdata = NSData(bytes: bytes as [UInt8], length: bytes.count)
        let str = String(data: nsdata as Data, encoding: String.Encoding.utf8)
        return str ?? ""
    }

    static func parseRawDataToInt(data:Data)->Int{
        var num:UInt8 = 0
        data.copyBytes(to: &num, count: MemoryLayout<Int>.size)
        return Int(num)
    }

    func hexString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        let hexString = map { String(format: format, $0) }.joined()
        return hexString
    }


}
extension String {


    func dataFromHexadecimalString() -> Data? {
        let trimmedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")

        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them

        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.count))
        if found == nil || found?.range.location == NSNotFound || trimmedString.count % 2 != 0 {
            return nil
        }

        // everything ok, so now let's build NSData

        let data = NSMutableData(capacity: trimmedString.count / 2)

        var index = trimmedString.startIndex
        while index < trimmedString.endIndex {
            let byteString = trimmedString.substring(with: (index ..< trimmedString.index(after: trimmedString.index(after: index))))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num] as [UInt8], length: 1)
            index = trimmedString.index(after: trimmedString.index(after: index))
        }

        //        for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = trimmedString.index(after: trimmedString.index(after: index)) {
        //            let byteString = trimmedString.substring(with: (index ..< trimmedString.index(after: trimmedString.index(after: index))))
        //            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
        //            data?.append([num] as [UInt8], length: 1)
        //        }

        return data as Data?
    }

    func toPlainData()-> Data?{
        return self.data(using: .utf8)
    }

    static func hexToString(hex: String) -> String? {
        print("Begin")
        guard hex.count % 2 == 0 else {
            return nil
        }

        var bytes = [CChar]()

        var startIndex = hex.index(hex.startIndex, offsetBy: 0)
        while startIndex < hex.endIndex {
            let endIndex = hex.index(startIndex, offsetBy: 2)
            let substr = hex[startIndex..<endIndex]

            if let byte = Int8(substr, radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }

            startIndex = endIndex
        }

        bytes.append(0)
        print("End")
        print("String(cString: bytes) ============>\(String(cString: bytes))" )
        return String(cString: bytes)
    }
   static func hexToIntString(hexValue:String) -> String? {
        if let value = UInt8(hexValue, radix: 16) {
            print("checking battery value assign time")
            return "\(value)"
        }
        return nil
    }


    static func stringToHexString(regularString:String) -> String {
    let data = Data(regularString.utf8)
    let hexString = data.map{ String(format:"%02x", $0) }.joined()
    return hexString
    }
}

extension Date {
    func currentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy"
        let dateInFormat = dateFormatter.string(from: Date())
        //print(dateInFormat)
        return "\(dateInFormat)\0"
    }
    func currentTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateInFormat = dateFormatter.string(from: Date())
        //print(dateInFormat)
        return "\(dateInFormat)\0"
    }
    
    func currentDateTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateInFormat = dateFormatter.string(from: Date())
        //print(dateInFormat)
        return dateInFormat
    }
    
//

}



