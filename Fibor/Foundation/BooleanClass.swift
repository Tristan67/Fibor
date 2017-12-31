//
//  BooleanClass.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class BooleanClass: ClassDef {
    
    init() {
        super.init(BaseDataType.boolean.rawValue, BaseDataType.object.rawValue, BooleanClass.initializer, BooleanClass.loadMethods(), [])
    }
    
    
    private static let initializer = InitializerDef(ReturnSt(NativeExp({ context in
        let oldThis = context.this!
        let newThis = BooleanInstance(false, oldThis.address, oldThis.references)
        context.store.replaceInstance(at: oldThis.address, with: newThis)
        return context.voidInstance
    })))
    
    
    private static func loadMethods() -> [MethodDef] {
        var methods = [MethodDef]()
        
        methods.append({
            let methName = PRE_OP_PREFIX + "!"
            let paramType = TupleType([])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let oppositeValue = !((context.store[thisAddress] as! BooleanInstance).value)
                return context.initBoolean(oppositeValue)
            })
            
            return MethodDef(false, false, methName, [], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "=="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.boolean.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let isEqual = (context.store[thisAddress] as! BooleanInstance).value == (context.store[argAddress] as! BooleanInstance).value
                return context.initBoolean(isEqual)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "!="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.boolean.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let result = (context.store[thisAddress] as! BooleanInstance).value != (context.store[argAddress] as! BooleanInstance).value
                return context.initBoolean(result)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "&&"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.boolean.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let and = (context.store[thisAddress] as! BooleanInstance).value && (context.store[argAddress] as! BooleanInstance).value
                return context.initBoolean(and)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "||"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.boolean.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let or = (context.store[thisAddress] as! BooleanInstance).value || (context.store[argAddress] as! BooleanInstance).value
                return context.initBoolean(or)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = "stringify"
            let paramType = TupleType([])
            let returnType = ObjectType(BaseDataType.string.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let thisValue = (context.store[thisAddress] as! BooleanInstance).value
                return context.initString("\(thisValue)")
            })
            
            return MethodDef(false, false, methName, [], signature, BaseDataType.boolean.rawValue, ReturnSt(native))
        }())
        
        return methods
    }
    
}

