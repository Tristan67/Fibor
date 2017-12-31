//
//  AssignmentExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class AssignmentExp: ExpressionNode {
    
    let reciever: ExpressionNode
    let value: ExpressionNode
    
    init(_ reciever: ExpressionNode, _ value: ExpressionNode) {
        self.reciever = reciever
        self.value = value
        super.init(.assignment)
    }
    
}

