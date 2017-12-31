//
//  ReferenceExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ReferenceExp: ExpressionNode {
    
    let identifier: String
    
    init(_ identifier: String) {
        self.identifier = identifier
        super.init(.reference)
    }
    
}

