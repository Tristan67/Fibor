//
//  IntegerInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class IntegerInstance: ObjectInstance {
    
    let value: Int
    
    override var debugDescription: String {
        return "(\(type)(\(value))(arc: \(arc)) @\(address))"
    }
    
    init(_ value: Int, _ address: Int) {
        self.value = value
        super.init(ObjectType(BaseDataType.integer.rawValue), address, [:])
    }
    
    init(_ value: Int, _ address: Int, _ properties: [String: Int]) {
        self.value = value
        super.init(ObjectType(BaseDataType.integer.rawValue), address, properties)
    }
    
}

