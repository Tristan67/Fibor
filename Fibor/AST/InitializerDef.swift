//
//  InitializerDef.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/4/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class InitializerDef: DefinitionNode {
    
    let body: StatementNode
    
    init(_ body: StatementNode) {
        self.body = body
        super.init(.initializer)
    }
    
    convenience init() {
        self.init(ImplicitReturnSt())
    }
    
}

