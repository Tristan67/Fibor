//
//  ExtensionDef.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/17/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ExtensionDef: DefinitionNode {
    
    let className: String
    var methods: [MethodDef]
    var properties: [PropertyDef]
    
    init(_ className: String, _ methods: [MethodDef], _ properties: [PropertyDef]) {
        self.className = className
        self.methods = methods
        self.properties = properties
        super.init(.extensionDef)
    }
    
}

