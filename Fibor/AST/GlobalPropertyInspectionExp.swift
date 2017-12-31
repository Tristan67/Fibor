//
//  GlobalPropertyInspectionExp.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/7/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class GlobalPropertyInspectionExp: ExpressionNode {
    
    let globalName: String
    let propertyName: String
    
    init(_ globalName: String, _ propertyName: String) {
        self.globalName = globalName
        self.propertyName = propertyName
        super.init(.globalPropertyInspection)
    }
    
}

