//
//  StringClass.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class StringClass: ClassDef {
    
    init() {
        super.init(BaseDataType.string.rawValue, BaseDataType.object.rawValue, StringClass.initializer, StringClass.loadMethods(), [])
    }
    
    
    private static let initializer = InitializerDef(ReturnSt(NativeExp({ context in
        let oldThis = context.this!
        let newThis = StringInstance("", oldThis.references, oldThis.address)
        context.store.replaceInstance(at: oldThis.address, with: newThis)
        return context.voidInstance
    })))
    
    
    private static func loadMethods() -> [MethodDef] {
        var methods = [MethodDef]()
        
        methods.append({
            let methName = IN_OP_PREFIX + "+"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.string.rawValue)])
            let returnType = ObjectType(BaseDataType.string.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let sum = (context.store[thisAddress] as! StringInstance).value + (context.store[argAddress] as! StringInstance).value
                return context.initString(sum)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.string.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = "length"
            let paramType = TupleType([])
            let returnType = ObjectType(BaseDataType.integer.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let thisValue = (context.store[thisAddress] as! StringInstance).value
                return context.initInteger(thisValue.count)
            })
            
            return MethodDef(false, false, methName, [], signature, BaseDataType.string.rawValue, ReturnSt(native))
        }())
        
        //TODO: Make more methods
        
        return methods
    }
    
}

