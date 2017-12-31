//
//  Instance.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/5/17 (Major revision on 10/8/2017).
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum InstanceType {
    case block
    case object
    case void
}


class Instance: CustomDebugStringConvertible {
    
    //-----Instance Properties-----
    
    let instanceType: InstanceType
    
    let type: Type
    
    let address: Int
    
    var references: [String: Int]
    
    var arc: UInt = 0
    
    var debugDescription: String {
        return "(\(type)(arc: \(arc)) @\(address))"
    }
    
    
    //-----Initializers-----
    
    init(_ instanceType: InstanceType, _ type: Type, _ address: Int, _ references: [String: Int]) {
        self.instanceType = instanceType
        self.type = type
        self.address = address
        self.references = references
    }
    
    
    //-----Instance Methods-----
    
    /*func get(_ identifier: String) -> Instance? {
        return references[identifier]
    }
    
    func set(_ identifier: String, to value: Instance) {
        references[identifier] = value
    }*/
    
    //TODO: Make subscripts and/or the methods above
    
}

