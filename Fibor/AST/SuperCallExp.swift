//
//  SuperCallExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/17/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class SuperCallExp: ExpressionNode {
    
    let methodName: String
    let arguments: [ExpressionNode]
    
    init(_ methodName: String, _ arguments: [ExpressionNode]) {
        self.methodName = methodName
        self.arguments = arguments
        super.init(.superCall)
    }
    
}

