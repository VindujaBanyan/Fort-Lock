//
//  AttributedString+Extensions.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/16/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import UIKit
extension NSMutableAttributedString {
    func imageAttributedString(_ imageName: String) -> NSMutableAttributedString {
        let iconImage = UIImage(named: imageName)!
        let font = UIFont.systemFont(ofSize: 14.0) // set accordingly to your font, you might pass it in the function
        let textAttachment = NSTextAttachment()
        let image = iconImage
        textAttachment.image = image
        let mid = font.descender + font.capHeight
        // x value doesnt work . Its altered at run time
        textAttachment.bounds = (CGRect(x: 5, y: font.descender - image.size.height / 2 + mid + 1, width: image.size.width + 3, height: image.size.height + 3))
        let normalString = NSMutableAttributedString(string: " ")
        let iconString = NSAttributedString(attachment: textAttachment)
        normalString.append(iconString)
        normalString.append(NSMutableAttributedString(string: " "))
        return normalString
    }

    func imageAttributedStringForFont(_ font: UIFont, _ imageName: String) -> NSMutableAttributedString {
        let iconImage = UIImage(named: imageName)!
        let textAttachment = NSTextAttachment()
        let image = iconImage
        textAttachment.image = image
        let mid = font.descender + font.capHeight

        // x value doesnt work . Its altered at run time
        textAttachment.bounds = (CGRect(x: 5, y: font.descender - image.size.height / 2 + mid, width: image.size.width, height: image.size.height))
        let iconString = NSAttributedString(attachment: textAttachment)
        let mutableIconString = NSMutableAttributedString(attributedString: iconString)
        return mutableIconString
    }

    @discardableResult func normalUltraLight(_ text: String, fontSize: CGFloat = 14.0) -> NSMutableAttributedString {
        var normalUltraLightString = NSMutableAttributedString()
        if #available(iOS 8.2, *) {
            let attrs: [NSAttributedString.Key:AnyObject] =
            [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.ultraLight)]
            normalUltraLightString = NSMutableAttributedString(string:"\(text)", attributes:attrs)
        } else {
            // Fallback on earlier versions
        }

        self.append(normalUltraLightString)
        return self
    }
    
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
