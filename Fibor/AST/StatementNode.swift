//
//  StatementNode.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum StatementNodeType {
    case declaration
    case doSt
    case group
    case ifElse
    case implicitReturn
    case returnSt
    case whileLoop
}


class StatementNode: ASTNode {
    
    let stType: StatementNodeType
    
    init(_ stType: StatementNodeType) {
        self.stType = stType
        super.init(.statement)
    }
    
}

