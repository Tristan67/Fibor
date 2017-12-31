//
//  StringInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class StringInstance: ObjectInstance {
    
    let value: String
    
    override var debugDescription: String {
        return "(\(type)(\"\(value)\")(arc: \(arc)) @\(address))"
    }
    
    init(_ value: String, _ address: Int) {
        self.value = value
        super.init(ObjectType(BaseDataType.string.rawValue), address, [:])
    }
    
    init(_ value: String, _ properties: [String: Int], _ address: Int) {
        self.value = value
        super.init(ObjectType(BaseDataType.string.rawValue), address, properties)
    }
    
}

