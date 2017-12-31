//
//  DeclarationSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class DeclarationSt: StatementNode {
    
    let identifier: String
    let type: Type
    let value: ExpressionNode
    
    init(_ identifier: String, _ type: Type, value: ExpressionNode) {
        self.identifier = identifier
        self.type = type
        self.value = value
        super.init(.declaration)
    }
    
}

