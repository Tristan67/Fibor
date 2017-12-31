//
//  PropertyInspectionExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/6/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class PropertyInspectionExp: ExpressionNode {
    
    let owner: ExpressionNode
    let property: String
    
    init(_ owner: ExpressionNode, _ property: String) {
        self.owner = owner
        self.property = property
        super.init(.propertyInspection)
    }
    
}

