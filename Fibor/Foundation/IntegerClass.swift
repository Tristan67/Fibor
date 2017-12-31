//
//  IntegerClass.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class IntegerClass: ClassDef {
    
    init() {
        super.init(BaseDataType.integer.rawValue, BaseDataType.object.rawValue, IntegerClass.initializer, IntegerClass.loadMethods(), [])
    }
    
    
    private static let initializer = InitializerDef(ReturnSt(NativeExp({ context in
        let oldThis = context.this!
        let newThis = IntegerInstance(0, oldThis.address, oldThis.references)
        context.store.replaceInstance(at: oldThis.address, with: newThis)
        return context.voidInstance
    })))
    
    
    private static func loadMethods() -> [MethodDef] {
        var methods = [MethodDef]()
        
        methods.append({
            let methName = PRE_OP_PREFIX + "-"
            let paramType = TupleType([])
            let returnType = ObjectType(BaseDataType.integer.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let thisValue = (context.store[thisAddress] as! IntegerInstance).value
                return context.initInteger(-thisValue)
            })
            
            return MethodDef(false, false, methName, [], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "+"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.integer.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let sum = (context.store[thisAddress] as! IntegerInstance).value + (context.store[argAddress] as! IntegerInstance).value
                return context.initInteger(sum)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "-"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.integer.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let dif = (context.store[thisAddress] as! IntegerInstance).value - (context.store[argAddress] as! IntegerInstance).value
                return context.initInteger(dif)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + ">"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let greaterThanQ = (context.store[thisAddress] as! IntegerInstance).value > (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(greaterThanQ)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "<"
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let lessThanQ = (context.store[thisAddress] as! IntegerInstance).value < (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(lessThanQ)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + ">="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let greaterThanOrEqualToQ = (context.store[thisAddress] as! IntegerInstance).value >= (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(greaterThanOrEqualToQ)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "<="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let lessThanOrEqualToQ = (context.store[thisAddress] as! IntegerInstance).value <= (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(lessThanOrEqualToQ)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "=="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let isEqual = (context.store[thisAddress] as! IntegerInstance).value == (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(isEqual)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = IN_OP_PREFIX + "!="
            let paramName = "rhs"
            let paramType = TupleType([ObjectType(BaseDataType.integer.rawValue)])
            let returnType = ObjectType(BaseDataType.boolean.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let argAddress = context.find(paramName)!
                let result = (context.store[thisAddress] as! IntegerInstance).value != (context.store[argAddress] as! IntegerInstance).value
                return context.initBoolean(result)
            })
            
            return MethodDef(false, false, methName, [paramName], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        methods.append({
            let methName = "stringify"
            let paramType = TupleType([])
            let returnType = ObjectType(BaseDataType.string.rawValue)
            let signature = BlockType(paramType, returnType)
            
            let native = NativeExp({ context in
                let thisAddress = context.this!.address
                let thisValue = (context.store[thisAddress] as! IntegerInstance).value
                return context.initString("\(thisValue)")
            })
            
            return MethodDef(false, false, methName, [], signature, BaseDataType.integer.rawValue, ReturnSt(native))
        }())
        
        //TODO: Make more methods
        
        return methods
    }
    
}

