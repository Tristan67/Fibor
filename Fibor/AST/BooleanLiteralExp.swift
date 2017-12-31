//
//  BooleanLiteralExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BooleanLiteralExp: ExpressionNode {
    
    let value: Bool
    
    init(_ value: Bool) {
        self.value = value
        super.init(.booleanLiteral)
    }
    
}

