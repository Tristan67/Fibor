//
//  BlockInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BlockInstance: Instance {
    
    let paramNames: [String]
    let paramType: TupleType
    let returnType: Type
    let body: StatementNode

    var signature: BlockType {
        return BlockType(paramType, returnType)
    }
    
    
    init(_ captures: [String: Int], _ paramNames: [String], _ paramType: TupleType, _ returnType: Type, _ body: StatementNode, _ address: Int) {
        self.paramNames = paramNames
        self.paramType = paramType
        self.returnType = returnType
        self.body = body
        super.init(.block, signature, address, captures)
    }
    
}

