//
//  Type.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/15/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum TypeType {
    case block
    case object
    case tuple
    case void
}


protocol Type {
    
    var type: TypeType { get }
    
}


struct ObjectType: Type {
    
    let type: TypeType = .object
    let className: String
    
    init(_ className: String) {
        self.className = className
    }
    
    static func ==(_ lhs: ObjectType, _ rhs: ObjectType) -> Bool {
        return lhs.className == rhs.className
    }
    
}


struct BlockType: Type {
    
    let type: TypeType = .block
    let paramTypes: TupleType
    let returnType: Type
    
    init(_ paramTypes: TupleType, _ returnType: Type) {
        self.paramTypes = paramTypes
        self.returnType = returnType
    }
    
}


struct TupleType: Type {
    
    let type: TypeType = .tuple
    let memberTypes: [Type]
    
    init(_ memberTypes: [Type]) {
        self.memberTypes = memberTypes
    }
    
}


struct VoidType: Type {
    
    let type: TypeType = .void
    
}

