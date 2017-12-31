//
//  GlobalCallExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/7/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class GlobalCallExp: ExpressionNode {
    
    let globalName: String
    let methodName: String
    let arguments: [ExpressionNode]
    
    init(_ globalName: String, _ methodName: String, _ arguments: [ExpressionNode]) {
        self.globalName = globalName
        self.methodName = methodName
        self.arguments = arguments
        super.init(.globalCall)
    }
    
}

