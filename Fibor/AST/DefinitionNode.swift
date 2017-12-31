//
//  DeclarationNode.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum DefinitionNodeType {
    case classDef
    case extensionDef
    case initializer
    case method
    case property
}


class DefinitionNode: ASTNode {
    
    let defType: DefinitionNodeType
    
    init(_ defType: DefinitionNodeType) {
        self.defType = defType
        super.init(.definition)
    }
    
}

