//
//  DigiPinTableViewCell.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 5/17/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit

class DigiPinTableViewCell: UITableViewCell,UITextFieldDelegate, BackspaceTextFieldDelegate {
        
    @IBOutlet weak var lblCount: UILabel!
    @IBOutlet weak var txtFieldTitle: UITextField!
    @IBOutlet weak var txtFieldFirstPin: BackspaceTextField!
    @IBOutlet weak var txtFieldSecondPin: BackspaceTextField!
    @IBOutlet weak var txtFieldThirdPin: BackspaceTextField!
    @IBOutlet weak var txtFieldFourthPin: BackspaceTextField!
    @IBOutlet weak var cardView: UIView!
    var textFields: [BackspaceTextField] {
            return [txtFieldFirstPin, txtFieldSecondPin, txtFieldThirdPin, txtFieldFourthPin]
        }
    var indexPathRow = Int()
    var valueChanged:((_ value: String,_ index: Int,_ indexPathRow: Int) -> Void)?
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textFields.forEach { $0.backspaceTextFieldDelegate = self }
        lblCount.layer.masksToBounds = true
        lblCount.layer.cornerRadius = 4
        txtFieldTitle.delegate = self
        txtFieldFirstPin.delegate = self
        txtFieldSecondPin.delegate = self
        txtFieldThirdPin.delegate = self
        txtFieldFourthPin.delegate = self
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 10.0
        cardView.layer.shadowColor = UIColor.gray.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        cardView.layer.shadowRadius = 6.0
        cardView.layer.shadowOpacity = 0.7
        txtFieldTitle.placeholder = "Name"
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: txtFieldTitle.frame.height - 1, width: self.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.lightGray.cgColor
        txtFieldTitle.borderStyle = UITextField.BorderStyle.none
        txtFieldTitle.layer.addSublayer(bottomLine)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField != self.txtFieldTitle {
        let newPosition = textField.endOfDocument
        DispatchQueue.main.async {
        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.txtFieldTitle {
            if ((string.rangeOfCharacter(from: NSCharacterSet.letters) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) ||  (string.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil)) && (textField.text?.count)! < 20    {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                let textFieldText: NSString = (textField.text ?? "") as NSString
                let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
                self.valueChanged?(txtAfterUpdate,5,indexPathRow)
                return true
            } else if string == "" {
                let textFieldText: NSString = (textField.text ?? "") as NSString
                let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
                self.valueChanged?(txtAfterUpdate,5,indexPathRow)
                return true
            } else {
                return false
            }
        }else{
            let  char = string.cString(using: String.Encoding.utf8)!
                        let isBackSpace = strcmp(char, "\\b")

                        if isBackSpace == -92 {
                            print("Backspace was pressed")
                            textField.awakeFromNib()
                            textField.deleteBackward()
                            self.valueChanged?(string,textField == txtFieldFirstPin ? 0 : textField == txtFieldSecondPin ? 1 : textField == txtFieldThirdPin ? 2 : textField == txtFieldFourthPin ? 3 : 0,indexPathRow)
                            return false
                        }
        textField.text = string
        if string != "" {
        switch textField {
        case txtFieldFirstPin:
            txtFieldSecondPin.becomeFirstResponder()
        case txtFieldSecondPin:
            txtFieldThirdPin.becomeFirstResponder()
        case txtFieldThirdPin:
            txtFieldFourthPin.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        }
            self.valueChanged?(string,textField == txtFieldFirstPin ? 0 : textField == txtFieldSecondPin ? 1 : textField == txtFieldThirdPin ? 2 : textField == txtFieldFourthPin ? 3 : 0,indexPathRow)
        }
        return true
    }
    func textFieldDidEnterBackspace(_ textField: BackspaceTextField) {
        guard let index = textFields.index(of: textField) else {
                    return
                }

                if index > 0 {
                    textFields[index - 1].becomeFirstResponder()
                } else {
                    self.endEditing(true)
                }
    }
}
class BackspaceTextField: UITextField {
    weak var backspaceTextFieldDelegate: BackspaceTextFieldDelegate?

    override func deleteBackward() {
        if text?.isEmpty ?? false {
            backspaceTextFieldDelegate?.textFieldDidEnterBackspace(self)
        }

        super.deleteBackward()
    }
}

protocol BackspaceTextFieldDelegate: class {
    func textFieldDidEnterBackspace(_ textField: BackspaceTextField)
}
