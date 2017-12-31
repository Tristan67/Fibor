//
//  String+Extension.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


extension String {
    
    subscript (_ i: Int) -> String {
        return self[i...i]
    }
    
    subscript (_ range: Range<Int>) -> String {
        let lower = index(startIndex, offsetBy: range.lowerBound)
        let upper = index(lower, offsetBy: range.count)
        let substring = self[lower..<upper]
        return String(substring)
    }
    
    subscript (_ closedRange: ClosedRange<Int>) -> String {
        let lower = index(startIndex, offsetBy: closedRange.lowerBound)
        let upper = index(lower, offsetBy: closedRange.count)
        let substring = self[lower..<upper]
        return String(substring)
    }
    
    func isWhitespace() -> Bool {
        return count == 1 && " \r\t\u{000B}\u{000C}\0".contains(self)
    }
    
    func isNewline() -> Bool {
        return self == "\n"
    }
    
    func isDelimiter() -> Bool {
        return count == 1 && "{}()[],".contains(self)
    }
    
    func isDot() -> Bool {
        return self == "."
    }
    
    func isLowerAlphaChar() -> Bool {
        return count == 1 && "abcdefghijklmnopqrstuvwxyz".contains(self)
    }
    
    func isUpperAlphaChar() -> Bool {
        return count == 1 && "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(self)
    }
    
    func isAlphaChar() -> Bool {
        return isLowerAlphaChar() || isUpperAlphaChar()
    }
    
    func isDigit() -> Bool {
        return count == 1 && "0123456789".contains(self)
    }
    
    func isOperatorChar() -> Bool {
        return count == 1 && "+-*/%=!&|^~<>?\':#".contains(self)
    }
    
}

