//
//  BlockLiteralExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BlockLiteralExp: ExpressionNode {
    
    let captures: [String: ExpressionNode]
    let parameterNames: [String]
    let type: BlockType
    let body: StatementNode
    
    init(_ captures: [String: ExpressionNode], _ parameterNames: [String], _ type: BlockType, _ body: StatementNode) {
        self.captures = captures
        self.parameterNames = parameterNames
        self.type = type
        self.body = body
        super.init(.blockLiteral)
    }
    
}

