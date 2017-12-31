//
//  ClassDef.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ClassDef: DefinitionNode {
    
    let className: String
    let superName: String?
    var initializer: InitializerDef
    var methods: [MethodDef]
    var properties: [PropertyDef]
    
    init(_ className: String, _ superName: String?, _ initializer: InitializerDef, _ methods: [MethodDef], _ properties: [PropertyDef]) {
        self.className = className
        self.superName = superName
        self.initializer = initializer
        self.methods = methods
        self.properties = properties
        super.init(.classDef)
    }
    
}

