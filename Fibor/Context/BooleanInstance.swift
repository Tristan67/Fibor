//
//  BooleanInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BooleanInstance: ObjectInstance {
    
    let value: Bool
    
    override var debugDescription: String {
        return "(\(type)(\(value))(arc: \(arc)) @\(address))"
    }
    
    init(_ value: Bool, _ address: Int) {
        self.value = value
        super.init(ObjectType(BaseDataType.boolean.rawValue), address, [:])
    }
    
    init(_ value: Bool, _ address: Int, _ properties: [String: Int]) {
        self.value = value
        super.init(ObjectType(BaseDataType.boolean.rawValue), address, properties)
    }
    
}

