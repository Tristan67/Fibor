//
//  ExpressionNode.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum ExpressionNodeType {
    case assignment
    case blockInvocation
    case blockLiteral
    case booleanLiteral
    case call
    case globalCall
    case globalPropertyInspection
    case initialization
    case integerLiteral
    case native
    case propertyInspection
    case reference
    case stringLiteral
    case superCall
    case thisLiteral
}


class ExpressionNode: ASTNode {
    
    let expType: ExpressionNodeType
    
    init(_ expType: ExpressionNodeType) {
        self.expType = expType
        super.init(.expression)
    }
    
}

