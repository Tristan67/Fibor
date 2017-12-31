//
//  MethodDef.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class MethodDef: DefinitionNode {
    
    let identifier: String
    let paramNames: [String]
    let signature: BlockType
    let definedInClass: String
    let body: StatementNode
    let isGlobal: Bool
    let isPrivate: Bool
    
    init(_ isGlobal: Bool, _ isPrivate: Bool, _ identifier: String, _ paramNames: [String], _ signature: BlockType, _ definedInClass: String, _ body: StatementNode) {
        self.identifier = identifier
        self.paramNames = paramNames
        self.signature = signature
        self.definedInClass = definedInClass
        self.body = body
        self.isGlobal = isGlobal
        self.isPrivate = isPrivate
        super.init(.method)
    }
    
}

