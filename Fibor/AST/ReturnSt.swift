//
//  ReturnSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ReturnSt: StatementNode {
    
    let value: ExpressionNode
    
    init(_ value: ExpressionNode) {
        self.value = value
        super.init(.returnSt)
    }
    
}

