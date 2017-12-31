//
//  StringLiteralExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class StringLiteralExp: ExpressionNode {
    
    let value: String
    
    init(_ value: String) {
        self.value = value
        super.init(.stringLiteral)
    }
    
}

