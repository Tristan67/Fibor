//
//  WhileSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/6/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class WhileSt: StatementNode {
    
    let condition: ExpressionNode
    let statement: StatementNode
    
    init(_ condition: ExpressionNode, _ statement: StatementNode) {
        self.condition = condition
        self.statement = statement
        super.init(.whileLoop)
    }
    
}

