//
//  ObjectClass.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class ObjectClass: ClassDef {
    
    init() {
        super.init(BaseDataType.object.rawValue, nil, InitializerDef(), ObjectClass.loadMethods(), [])
    }
    
    private static func loadMethods() -> [MethodDef] {
        var methods = [MethodDef]()
        
        //TODO: Make "Object" methods
        
        return methods
    }
    
}

