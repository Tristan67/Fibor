//
//  PropertyDef.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class PropertyDef: DefinitionNode {
    
    let identifier: String
    let type: Type
    let definedInClass: String
    let value: ExpressionNode
    let isGlobal: Bool
    let isPrivate: Bool
    
    init(_ isGlobal: Bool, _ isPrivate: Bool, _ identifier: String, _ type: Type, _ definedInClass: String, _ value: ExpressionNode) {
        self.identifier = identifier
        self.type = type
        self.definedInClass = definedInClass
        self.value = value
        self.isGlobal = isGlobal
        self.isPrivate = isPrivate
        super.init(.property)
    }
    
}

