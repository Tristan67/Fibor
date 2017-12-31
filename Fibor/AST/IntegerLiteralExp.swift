//
//  IntegerLiteralExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class IntegerLiteralExp: ExpressionNode {
    
    let value: Int
    
    init(_ value: Int) {
        self.value = value
        super.init(.integerLiteral)
    }
    
}

