//
//  CallExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class CallExp: ExpressionNode {
    
    var reciever: ExpressionNode
    let methodName: String
    let arguments: [ExpressionNode]
    
    init(_ reciever: ExpressionNode, _ methodName: String, _ arguments: [ExpressionNode]) {
        self.reciever = reciever
        self.methodName = methodName
        self.arguments = arguments
        super.init(.call)
    }
    
}

