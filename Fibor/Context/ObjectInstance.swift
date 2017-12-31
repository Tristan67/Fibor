//
//  ObjectInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ObjectInstance: Instance {
    
    init(_ dataType: ObjectType, _ address: Int, _ properties: [String: Int]) {
        super.init(.object, dataType, address, properties)
    }
    
}

