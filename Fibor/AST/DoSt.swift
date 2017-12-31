//
//  DoSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class DoSt: StatementNode {
    
    let expression: ExpressionNode
    
    init(_ expression: ExpressionNode) {
        self.expression = expression
        super.init(.doSt)
    }
    
}

