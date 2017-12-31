//
//  Context+Evaluater.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/14/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum EvaluaterError: Error {
    case referencedSuperInGlobalScope
    case referencedUndefinedThis
    case referencedUndeclaredVariable(identifier: String)
    case referencedUndefindedFunction(recieverDataType: String, identifier: String)
    case calledUndefinedInitializer(dataType: String)
    case mismatchedTypesInAssignment
    case assignedToNonReferenceExpression
    case calledMethodOnNonObjectInstance
    case invokedNonBlockInstance
    case argumentTypesDoNotMatchBlockParameterTypes
    case returnedInvalidDataType(expected: Type, returned: Type)
    case inspectedPropertyOnNonObjectInstance
    case inspectedNonExistantProperty(propertyName: String, className: String)
    case inspectedNonExistantGlobalProperty(propertyName: String, dataType: String)
    case calledSuperOfUndefinedThis
    case thisHasNoSuper(thisClassName: String)
    case noVisibleMethodForClass(className: String, methName: String, signature: TupleType, isGlobal: Bool)
}


//TODO: make all "evaluate" funcs return an address instead of an instance in order to avoid the constant changing of instances' references in the store (i.e to keep things consistant/concurrent/parallel)


extension Context {
    
    func evaluate(_ expression: ExpressionNode) throws -> Instance {
        
        switch expression.expType {
        case .assignment: return try evaluateAssignment(expression as! AssignmentExp)
        case .blockInvocation: return try evaluateBlockInvocation(expression as! BlockInvocationExp)
        case .blockLiteral: return try evaluateBlockLiteral(expression as! BlockLiteralExp)
        case .booleanLiteral: return evaluateBooleanLiteral(expression as! BooleanLiteralExp)
        case .call: return try evaluateCall(expression as! CallExp)
        case .globalCall: return try evaluateGlobalCall(expression as! GlobalCallExp)
        case .globalPropertyInspection: return try evaluateGlobalPropertyInspection(expression as! GlobalPropertyInspectionExp)
        case .initialization: return try evaluateInitialization(expression as! InitializationExp)
        case .integerLiteral: return evaluateIntegerLiteral(expression as! IntegerLiteralExp)
        case .native: return evaluateNative(expression as! NativeExp)
        case .propertyInspection: return try evaluatePropertyInspection(expression as! PropertyInspectionExp)
        case .reference: return try evaluateReference(expression as! ReferenceExp)
        case .stringLiteral: return evaluateStringLiteral(expression as! StringLiteralExp)
        case .superCall: return try evaluateSuperCall(expression as! SuperCallExp)
        case .thisLiteral: return try evaluateThisLiteral()
        //default: fatalError("Attempted to evaluate unknown expression type: \(expression.expType)") //Temporary
        }
        
    }
    
    private func evaluateAssignment(_ assignment: AssignmentExp) throws -> Instance {
        //TODO: Cannot assign to Void
        
        if assignment.reciever.expType == .reference {
            let varID = (assignment.reciever as! ReferenceExp).identifier
            
            if let scope = findYoungestScopeWith(varID) {
                let value = try evaluate(assignment.value)
                let varMeta = scope[varID]!
                
                if !typeIsValid(value.type, varMeta.dataType) {
                    throw EvaluaterError.mismatchedTypesInAssignment
                }
                
                scope.point(varID, to: value.address)
                store.incrementARCForInstanceTree(at: value.address)
                store.decrementARCForInstanceTree(at: varMeta.address)
                print("assigned (to @\(value.address))")
                
                //Remove instance at `value.address` from unreferencedSet IF it is in unreferencedSet
                //(because it IS referenced now)
                if currentScope.unreferencedSetContains(value.address) {
                    removeInstanceTreeFromUnreferencedSet(at: value.address)
                }
                
                return value
            }
            
            //TODO: assigned to undeclared variable
            fatalError("ASSIGNED TO UNDECLARED VARIABLE")
            
        } else if assignment.reciever.expType == .propertyInspection {
            let inspection = assignment.reciever as! PropertyInspectionExp
            let owner = try evaluate(inspection.owner)
            
            if owner.instanceType != .object {
                throw EvaluaterError.inspectedPropertyOnNonObjectInstance
            }
            
            let ownerClassName = (owner.type as! ObjectType).className
            
            let canBePrivate: Bool
            if let privateAccessName = privateAccessName, ownerClassName == privateAccessName || classInherits(ownerClassName, privateAccessName) {
                canBePrivate = true
            } else {
                canBePrivate = false
            }
            
            if let propDef = getProperty(ownerClassName, inspection.property, false, !canBePrivate) {
                
                let value = try evaluate(assignment.value)
                
                if !typeIsValid(value.type, propDef.type) {
                    throw EvaluaterError.mismatchedTypesInAssignment
                }
                
                let internalPropID = (propDef.isPrivate ? "<" + propDef.definedInClass + ">" : "") + inspection.property
                let oldPropertyAddress = owner.references[internalPropID]!
                
                //Assign the new value
                owner.references[internalPropID] = value.address
                
                //Increment @ `value.address` by the owner's `arc` (1)
                //Decrement @ `oldPropertyAdress` by the owner's `arc` (2)
                //(Do this because (1) a property of an object should "live" for at least as long as the object that owns it, which is why objects are incremented by "trees", so everytime the object is incremented, its properties/references are too. Thus, (2) each property has at least as many pointers as its owner do to the pointers on the owner, and not strictly because they explicitly point to the property, thus these implict pointers need to be removed @ `oldPropertyAddress`)
                let ownerARC = owner.arc
                store.incrementARCForInstanceTree(at: value.address, by: ownerARC)
                store.decrementARCForInstanceTree(at: oldPropertyAddress, by: ownerARC)
                
                print("assigned (to @\(value.address))")
                
                //Remove instance at `value.address` from unreferencedSet IF it is in unreferencedSet
                //(because it IS referenced now)
                if currentScope.unreferencedSetContains(value.address) {
                    removeInstanceTreeFromUnreferencedSet(at: value.address)
                }
                
                return value
            }
            
            //TODO: assigned to undefined property
            fatalError("ASSIGNED TO UNDEFINED PROPERTY")
            
        } else if assignment.reciever.expType == .globalPropertyInspection {
            let globalInspection = assignment.reciever as! GlobalPropertyInspectionExp
            
            if let propDef = getProperty(globalInspection.globalName, globalInspection.propertyName, true, globalInspection.globalName != privateAccessName) {
                
                let value = try evaluate(assignment.value)
                
                if !typeIsValid(value.type, propDef.type) {
                    throw EvaluaterError.mismatchedTypesInAssignment
                }
                
                let globalPropertyName = globalInspection.globalName + "." + globalInspection.propertyName
                let oldPropertyAddress = globalScope[globalPropertyName]!.address
                
                globalScope.point(globalPropertyName, to: value.address)
                store.incrementARCForInstanceTree(at: value.address)
                store.decrementARCForInstanceTree(at: oldPropertyAddress)
                
                //Remove instance at `value.address` from unreferencedSet IF it is in unreferencedSet
                //(because it IS referenced now)
                if currentScope.unreferencedSetContains(value.address) {
                    removeInstanceTreeFromUnreferencedSet(at: value.address)
                }
                
                return value
            }
            
            //TODO: assigned to undefined global property
            fatalError("ASSIGNED TO UNDEFINED GLOBAL PROPERTY")
        }
        
        throw EvaluaterError.assignedToNonReferenceExpression
    }
    
    private func evaluateBlockInvocation(_ invocation: BlockInvocationExp) throws -> Instance {
        let block = try { () -> BlockInstance in
            let instance = try evaluate(invocation.block)
            if instance.instanceType == .block {
                return instance as! BlockInstance
            } else {
                throw EvaluaterError.invokedNonBlockInstance
            }
        }()
        
        let argumentInstances = try helpEvaluateArguments(invocation.arguments)
        let argumentSignature = Context.helpMakeTupleType(from: argumentInstances)
        
        
        if !tupleTypeIsValid(argumentSignature, block.paramType) {
            throw EvaluaterError.argumentTypesDoNotMatchBlockParameterTypes
        }
        
        //Create the action's scope
        let actionScope = Scope(.restricted)
        
        //Declare the captures in scope
        for (capture, address) in block.references {
            let captureVarMeta = VarMeta(address, store[address]!.type)
            actionScope.declare(capture, with: captureVarMeta)
            store.incrementARCForInstanceTree(at: captureVarMeta.address)
        }
        
        //Declare the arguments in scope
        for (i, parameterName) in block.paramNames.enumerated() {
            let argumentVarMeta = VarMeta(argumentInstances[i].address, block.paramType.memberTypes[i])
            actionScope.declare(parameterName, with: argumentVarMeta)
            store.incrementARCForInstanceTree(at: argumentVarMeta.address)
            
            //Remove `argumentInstances[i]` from current (calling) scope's unreferenced set if it is there
            //(Do this because if the instance is initialized as an argument during this method call, the instance could be dealloc'd when `actionScope` exits and also try to be dealloc'd from the parent/calling scope's unreferenced set when it exits as it would still be there)
            if currentScope.unreferencedSetContains(argumentVarMeta.address) {
                currentScope.removeFromUnreferencedSet(argumentVarMeta.address)
            }
        }
        
        //Push the scope into context and get its index
        let actionScopeIndex = stratifyScopes(actionScope)
        
        //Perform the block's statement
        try perform(block.body)
        
        //Get the instance returned from this action
        let resultInstance: Instance
        if let resultAddress = currentScope.resultPointer {
            resultInstance = store[resultAddress]!
        } else {
            resultInstance = voidInstance
        }
        
        //Put `resultInstance` in external scope's unreferenced set IF it is in current scope's
        if currentScope.unreferencedSetContains(resultInstance.address) {
            parentScope.addToUnreferencedSet(resultInstance.address)
            
            //Remove `resultInstance` from current scope's unreferenced set so it won't be dealloc'd during scope exit
            removeInstanceTreeFromUnreferencedSet(at: resultInstance.address)
        }
        
        //Increment `resultInstance` so that it is not dealloc`d while exiting `actionScope`
        store.incrementARCForInstanceTree(at: resultInstance.address)
        
        //Strip/Exit all remaining scopes created during action
        popToScope(incuding: actionScopeIndex)
        
        //Softly decrement `resultInstance` to counter the increment above
        store.softlyDecrementARCForInstanceTree(at: resultInstance.address)
        
        //Ensure that the expected data type is returned
        if !typeIsValid(resultInstance.type, block.returnType) {
            throw EvaluaterError.returnedInvalidDataType(expected: block.returnType, returned: resultInstance.type)
        }
        
        return resultInstance
    }
    
    private func evaluateBlockLiteral(_ blockLiteral: BlockLiteralExp) throws -> BlockInstance {
        let captureInstances = try blockLiteral.captures.mapValues({ capturedExpression in
            return try evaluate(capturedExpression).address
        })
        return initBlock(captureInstances, blockLiteral.parameterNames, blockLiteral.type.paramTypes, blockLiteral.type.returnType, blockLiteral.body)
    }
    
    private func evaluateBooleanLiteral(_ booleanLiteral: BooleanLiteralExp) -> BooleanInstance {
        return initBoolean(booleanLiteral.value)
    }
    
    private func evaluateCall(_ call: CallExp) throws -> Instance {
        print("calling: \(call.methodName)")
        let recieverObject = try { () -> ObjectInstance in
            let instance = try evaluate(call.reciever)
            if instance.instanceType == .object {
                return instance as! ObjectInstance
            } else {
                throw EvaluaterError.calledMethodOnNonObjectInstance
            }
        }()
        
        let recieverClassName = (recieverObject.type as! ObjectType).className
        
        let argumentInstances = try helpEvaluateArguments(call.arguments)
        let argumentSignature = Context.helpMakeTupleType(from: argumentInstances)
        
        let methDef: MethodDef?
        
        print("about to find methDef")
        
        //Get the method definition
        if recieverClassName == privateAccessName {
            methDef = getVisibleMethFromClass(recieverClassName, call.methodName, argumentSignature, false)
        } else {
            print("must be public")
            methDef = getPublicMethFromClass(recieverClassName, call.methodName, argumentSignature, false)
        }
        
        if methDef == nil {
            throw EvaluaterError.noVisibleMethodForClass(className: recieverClassName, methName: call.methodName, signature: argumentSignature, isGlobal: false)
        }
        
        print("methDef found")
        
        //Remove `recieverObject.address` from parent/calling scope's unreferenced set if it is there because it will be referenced by `actionScope`'s "this" reference
        if currentScope.unreferencedSetContains(recieverObject.address) {
            currentScope.removeFromUnreferencedSet(recieverObject.address)
        }
        
        //Create the action's scope
        let actionScope = Scope(recieverObject, methDef!.definedInClass)
        
        //Increment @ `recieverObject.address` because it is being referenced by `actionScope`'s "this" reference
        store.incrementARCForInstanceTree(at: recieverObject.address)
        
        //Declare the arguments in scope
        for (i, parameterName) in methDef!.paramNames.enumerated() {
            let argumentVarMeta = VarMeta(argumentInstances[i].address, methDef!.signature.paramTypes.memberTypes[i])
            actionScope.declare(parameterName, with: argumentVarMeta)
            store.incrementARCForInstanceTree(at: argumentVarMeta.address)
            
            //Remove `argumentInstances[i]` from current (calling) scope's unreferenced set if it is there
            //(Do this because if the instance is initialized as an argument during this method call, the instance could be dealloc'd when `actionScope` exits and also try to be dealloc'd from the parent/calling scope's unreferenced set when it exits as it would still be there)
            if currentScope.unreferencedSetContains(argumentVarMeta.address) {
                currentScope.removeFromUnreferencedSet(argumentVarMeta.address)
            }
        }
        
        //Push the scope into context and get its index
        let actionScopeIndex = stratifyScopes(actionScope)
        
        //Perform the method's statement
        try perform(methDef!.body)
        
        //Get the instance returned from this action
        let resultInstance: Instance
        if let resultAddress = currentScope.resultPointer {
            resultInstance = store[resultAddress]!
        } else {
            resultInstance = voidInstance
        }
        
        //Put `resultInstance` in external scope's unreferenced set IF it is in current scope's
        if currentScope.unreferencedSetContains(resultInstance.address) {
            parentScope.addToUnreferencedSet(resultInstance.address)
            
            //Remove `resultInstance` from current scope's unreferenced set so it won't be dealloc'd during scope exit
            removeInstanceTreeFromUnreferencedSet(at: resultInstance.address)
        }
        
        //Increment `resultInstance` so that it is not dealloc`d while exiting `actionScope`
        store.incrementARCForInstanceTree(at: resultInstance.address)
        
        //Strip/Exit all remaining scopes created during action
        popToScope(incuding: actionScopeIndex)
        
        //Softly decrement `resultInstance` to counter the increment above
        store.softlyDecrementARCForInstanceTree(at: resultInstance.address)
        
        //Ensure that the expected data type is returned
        if !typeIsValid(resultInstance.type, methDef!.signature.returnType) {
            throw EvaluaterError.returnedInvalidDataType(expected: methDef!.signature.returnType, returned: resultInstance.type)
        }
        
        return resultInstance
    }
    
    private func evaluateGlobalCall(_ globalCall: GlobalCallExp) throws -> Instance {
        let argumentInstances = try helpEvaluateArguments(globalCall.arguments)
        let argumentSignature = Context.helpMakeTupleType(from: argumentInstances)
        
        let methDef: MethodDef?
        
        //Get the method definition
        if globalCall.globalName == privateAccessName {
            methDef = getVisibleMethFromClass(globalCall.globalName, globalCall.methodName, argumentSignature, true)
        } else {
            methDef = getPublicMethFromClass(globalCall.globalName, globalCall.methodName, argumentSignature, true)
        }
        
        if methDef == nil {
            throw EvaluaterError.noVisibleMethodForClass(className: globalCall.globalName, methName: globalCall.methodName, signature: argumentSignature, isGlobal: true)
        }
        
        //Create the action's scope
        let actionScope = Scope(globalCall.globalName)
        
        //Declare the arguments in scope
        for (i, parameterName) in methDef!.paramNames.enumerated() {
            let argumentVarMeta = VarMeta(argumentInstances[i].address, methDef!.signature.paramTypes.memberTypes[i])
            actionScope.declare(parameterName, with: argumentVarMeta)
            store.incrementARCForInstanceTree(at: argumentVarMeta.address)
            
            //Remove `argumentInstances[i]` from current (calling) scope's unreferenced set if it is there
            //(Do this because if the instance is initialized as an argument during this method call, the instance could be dealloc'd when `actionScope` exits and also try to be dealloc'd from the parent/calling scope's unreferenced set when it exits as it would still be there)
            if currentScope.unreferencedSetContains(argumentVarMeta.address) {
                currentScope.removeFromUnreferencedSet(argumentVarMeta.address)
            }
        }
        
        //Push the scope into context and get its index
        let actionScopeIndex = stratifyScopes(actionScope)
        
        //Perform the method's statement
        try perform(methDef!.body)
        
        //Get the instance returned from this action
        let resultInstance: Instance
        if let resultAddress = currentScope.resultPointer {
            resultInstance = store[resultAddress]!
        } else {
            resultInstance = voidInstance
        }
        
        //Put `resultInstance` in external scope's unreferenced set IF it is in current scope's
        if currentScope.unreferencedSetContains(resultInstance.address) {
            parentScope.addToUnreferencedSet(resultInstance.address)
            
            //Remove `resultInstance` from current scope's unreferenced set so it won't be dealloc'd during scope exit
            removeInstanceTreeFromUnreferencedSet(at: resultInstance.address)
        }
        
        //Increment `resultInstance` so that it is not dealloc`d while exiting `actionScope`
        store.incrementARCForInstanceTree(at: resultInstance.address)
        
        //Strip/Exit all remaining scopes created during action
        popToScope(incuding: actionScopeIndex)
        
        //Softly decrement `resultInstance` to counter the increment above
        store.softlyDecrementARCForInstanceTree(at: resultInstance.address)
        
        //Ensure that the expected data type is returned
        if !typeIsValid(resultInstance.type, methDef!.signature.returnType) {
            throw EvaluaterError.returnedInvalidDataType(expected: methDef!.signature.returnType, returned: resultInstance.type)
        }
        
        return resultInstance
    }
    
    private func evaluateGlobalPropertyInspection(_ globalInspection: GlobalPropertyInspectionExp) throws -> Instance {
        if let propDef = getProperty(globalInspection.globalName, globalInspection.propertyName, true, globalInspection.globalName != privateAccessName) {
            
            let globalPropertyName = globalInspection.globalName + "." + globalInspection.propertyName
            
            if let address = globalScope[globalPropertyName]?.address {
                return store[address]!
            } else {
                //Lazy initialization of global
                let instance = try evaluate(propDef.value)
                let varMeta = VarMeta(instance.address, propDef.type)
                globalScope.declare(globalPropertyName, with: varMeta)
                store.incrementARCForInstanceTree(at: instance.address)
                return instance
            }
            //TODO: Remove above check
            //(It is not necessary because all global property values are evaluated when their corresponding classes/extensions are injected. See Context+Injector.swift)
        }
        
        throw EvaluaterError.inspectedNonExistantGlobalProperty(propertyName: globalInspection.propertyName, dataType: globalInspection.globalName)
    }
    
    private func evaluateInitialization(_ initialization: InitializationExp) throws -> ObjectInstance {
        return try initObject(initialization.className)
    }
    
    private func evaluateIntegerLiteral(_ integerLiteral: IntegerLiteralExp) -> IntegerInstance {
        return initInteger(integerLiteral.value)
    }
    
    private func evaluateNative(_ native: NativeExp) -> Instance {
        return native.action(self)
    }
    
    private func evaluatePropertyInspection(_ inspection: PropertyInspectionExp) throws -> Instance {
        let owner = try evaluate(inspection.owner)
        
        if owner.instanceType != .object {
            throw EvaluaterError.inspectedPropertyOnNonObjectInstance
        }
        
        let ownerClassName = (owner.type as! ObjectType).className
        
        let canBePrivate: Bool
        if let privateAccessName = privateAccessName, ownerClassName == privateAccessName || classInherits(ownerClassName, privateAccessName) {
            canBePrivate = true
            print("\"\(inspection.property)\" can be private")
        } else {
            canBePrivate = false
        }
        
        print("ownerClassName: \"\(ownerClassName)\"\nprivateAccessName: \"\(privateAccessName!)\"")
        
        if let propDef = getProperty(ownerClassName, inspection.property, false, !canBePrivate) {
            let propertyAddress: Int
            
            if propDef.isPrivate {
                let internalPropID = "<" + propDef.definedInClass + ">" + inspection.property
                propertyAddress = owner.references[internalPropID]!
            } else {
                propertyAddress = owner.references[inspection.property]!
            }
            
            return store[propertyAddress]!
        }
        
        throw EvaluaterError.inspectedNonExistantProperty(propertyName: inspection.property, className: ownerClassName)
    }
    
    private func evaluateReference(_ reference: ReferenceExp) throws -> Instance {
        if let address = find(reference.identifier) {
            return store[address]!
        }
        throw EvaluaterError.referencedUndeclaredVariable(identifier: reference.identifier)
    }
    
    private func evaluateStringLiteral(_ stringLiteral: StringLiteralExp) -> StringInstance {
        return initString(stringLiteral.value)
    }
    
    private func evaluateSuperCall(_ superCall: SuperCallExp) throws -> Instance {
        if this == nil {
            throw EvaluaterError.calledSuperOfUndefinedThis
        }
        
        //Get the super class name
        let thisClassName = (this?.type as! ObjectType).className
        let superClassName = getClass(thisClassName)!.superName
        
        if superClassName == nil {
            throw EvaluaterError.thisHasNoSuper(thisClassName: thisClassName)
        }
        
        let argumentInstances = try helpEvaluateArguments(superCall.arguments)
        let argumentSignature = Context.helpMakeTupleType(from: argumentInstances)
        
        //Get the method definition (super calls cannot be on private methods)
        let methDef = getPublicMethFromClass(superClassName!, superCall.methodName, argumentSignature, false)
        
        if methDef == nil {
            throw EvaluaterError.noVisibleMethodForClass(className: superClassName!, methName: superCall.methodName, signature: argumentSignature, isGlobal: false)
        }
        
        //Create the action's scope
        let actionScope = Scope(this!, methDef!.definedInClass)
        
        //Increment @ `this!.address` because it is being referenced by `actionScope`'s "this" reference
        store.incrementARCForInstanceTree(at: this!.address)
        
        //Declare the arguments in scope
        for (i, parameterName) in methDef!.paramNames.enumerated() {
            let argumentVarMeta = VarMeta(argumentInstances[i].address, methDef!.signature.paramTypes.memberTypes[i])
            actionScope.declare(parameterName, with: argumentVarMeta)
            store.incrementARCForInstanceTree(at: argumentVarMeta.address)
            
            //Remove `argumentInstances[i]` from current (calling) scope's unreferenced set if it is there
            //(Do this because if the instance is initialized as an argument during this method call, the instance could be dealloc'd when `actionScope` exits and also try to be dealloc'd from the parent/calling scope's unreferenced set when it exits as it would still be there)
            if currentScope.unreferencedSetContains(argumentVarMeta.address) {
                currentScope.removeFromUnreferencedSet(argumentVarMeta.address)
            }
        }
        
        //Push the scope into context and get its index
        let actionScopeIndex = stratifyScopes(actionScope)
        
        //Perform the method's statement
        try perform(methDef!.body)
        
        //Get the instance returned from this action
        let resultInstance: Instance
        if let resultAddress = currentScope.resultPointer {
            resultInstance = store[resultAddress]!
        } else {
            resultInstance = voidInstance
        }
        
        //Put `resultInstance` in external scope's unreferenced set IF it is in current scope's
        if currentScope.unreferencedSetContains(resultInstance.address) {
            parentScope.addToUnreferencedSet(resultInstance.address)
            
            //Remove `resultInstance` from current scope's unreferenced set so it won't be dealloc'd during scope exit
            removeInstanceTreeFromUnreferencedSet(at: resultInstance.address)
        }
        
        //Increment `resultInstance` so that it is not dealloc`d while exiting `actionScope`
        store.incrementARCForInstanceTree(at: resultInstance.address)
        
        //Strip/Exit all remaining scopes created during action
        popToScope(incuding: actionScopeIndex)
        
        //Softly decrement `resultInstance` to counter the increment above
        store.softlyDecrementARCForInstanceTree(at: resultInstance.address)
        
        //Ensure that the expected data type is returned
        if !typeIsValid(resultInstance.type, methDef!.signature.returnType) {
            throw EvaluaterError.returnedInvalidDataType(expected: methDef!.signature.returnType, returned: resultInstance.type)
        }
        
        return resultInstance
    }
    
    private func evaluateThisLiteral() throws -> ObjectInstance {
        if this != nil {
            return this!
        } else {
            throw EvaluaterError.referencedUndefinedThis
        }
    }
    
    
    //-----Helpers-----
    
    private func helpEvaluateArguments(_ argumentExpressions: [ExpressionNode]) throws -> [Instance] {
        return try argumentExpressions.map({ argumentExpression in
            return try evaluate(argumentExpression)
        })
    }
    
    private static func helpMakeTupleType(from argumentInstances: [Instance]) -> TupleType {
        var types = [Type]()
        
        for (_, instance) in argumentInstances.enumerated() {
            types.append(instance.type)
        }
        
        return TupleType(types)
    }
    
}

