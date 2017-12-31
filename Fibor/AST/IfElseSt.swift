//
//  IfElseSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class IfElseSt: StatementNode {
    
    let condition: ExpressionNode
    let thenStatement: StatementNode
    let elseStatement: StatementNode?
    
    init(_ condition: ExpressionNode, _ thenStatement: StatementNode, elseStatement: StatementNode?) {
        self.condition = condition
        self.thenStatement = thenStatement
        self.elseStatement = elseStatement
        super.init(.ifElse)
    }
    
}

