//
//  BlockInvocationExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/6/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BlockInvocationExp: ExpressionNode {
    
    let block: ExpressionNode
    let arguments: [ExpressionNode]
    
    init(_ block: ExpressionNode, _ arguments: [ExpressionNode]) {
        self.block = block
        self.arguments = arguments
        super.init(.blockInvocation)
    }
    
}

