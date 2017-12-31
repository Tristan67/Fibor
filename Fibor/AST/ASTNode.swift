//
//  ASTNode.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum ASTNodeType {
    case definition
    case expression
    case statement
}


class ASTNode {
    
    let nodeType: ASTNodeType
    
    init(_ nodeType: ASTNodeType) {
        self.nodeType = nodeType
    }
    
}

