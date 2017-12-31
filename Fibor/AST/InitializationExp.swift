//
//  InitializationExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/4/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class InitializationExp: ExpressionNode {
    
    let className: String
    
    init(_ className: String) {
        self.className = className
        super.init(.initialization)
    }
    
}

