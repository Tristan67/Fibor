//
//  GroupSt.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class GroupSt: StatementNode {
    
    let statements: [StatementNode]
    
    init(_ statements: [StatementNode]) {
        self.statements = statements
        super.init(.group)
    }
    
}

