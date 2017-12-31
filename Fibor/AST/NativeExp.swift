//
//  NativeExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class NativeExp: ExpressionNode {
    
    let action: (Context) -> Instance
    
    init(_ action: @escaping (Context) -> Instance) {
        self.action = action
        super.init(.native)
    }
    
}

