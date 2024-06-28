//
//  DateTimeUtilities.swift
//  SmartLockiOS
//
//  Created by The Banyan Infotech on 24/06/24.
//  Copyright © 2024 payoda. All rights reserved.
//

import UIKit

class DateTimeUtilities: NSObject {
    
    func toDate(dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: dateString)
        }
        
        func toTime(timeString: String) -> Date? {
            let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
            return timeFormatter.date(from: timeString)
        }
        
        func toDateTime(dateTimeString: String) -> Date? {
           let  dateTimeFormatter = DateFormatter()
                    dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateTimeFormatter.date(from: dateTimeString)
        }
        
        func toDateString(date: Date) -> String {
            let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
        
        func toTimeString(time: Date) -> String {
            let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
            return timeFormatter.string(from: time)
        }
        
        func toDateTimeString(dateTime: Date) -> String {
            let  dateTimeFormatter = DateFormatter()
                     dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateTimeFormatter.string(from: dateTime)
        }
        
        func currentDateTimeString() -> String {
            let  dateTimeFormatter = DateFormatter()
                     dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateTimeFormatter.string(from: Date())
        }
}
