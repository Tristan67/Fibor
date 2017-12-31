//
//  Context.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17 (Major revision on 10/7/2017).
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


public class Context {
    
    //-----Type Properties-----
    
    private static let voidAddress = -1
    
    
    //-----Instance Properties-----
    
    var classes = [String: ClassDef]()
    
    var store = Store()
    
    private var scopes: [Scope] = [Scope(.restricted)]
    
    var globalScope: Scope {
        return scopes.first!
    }
    
    private var currentScopeIndex: Int {
        return scopes.count - 1
    }
    
    var currentScope: Scope {
        return scopes[currentScopeIndex]
    }
    
    var parentScope: Scope {
        return scopes[currentScopeIndex - 1]
    }
    
    var this: ObjectInstance? {
        print("looking for this")
        var scopeIndex = currentScopeIndex + 1
        
        repeat {
            scopeIndex -= 1
            print("looking in scopes[\(scopeIndex)] (\(scopes[scopeIndex].scopeType))")
            if let this = scopes[scopeIndex].this {
                print("found @\(this.address)")
                return this
            }
        } while scopeIndex >= 0 && scopes[scopeIndex].scopeType == .enlightened
        
        return nil
    }
    
    var privateAccessName: String? {
        var scopeIndex = currentScopeIndex + 1
        
        repeat {
            scopeIndex -= 1
            if let privateAccessName = scopes[scopeIndex].privateAccessNameType {
                return privateAccessName
            }
        } while scopeIndex >= 0 && scopes[scopeIndex].scopeType == .enlightened
        
        return nil
    }
    
    var voidInstance: VoidInstance {
        return store[Context.voidAddress] as! VoidInstance
    }
    
    
    //-----Initializers-----
    
    init() {
        store[Context.voidAddress] = VoidInstance(Context.voidAddress)
    }
    
    
    //-----Handling Scopes-----
    
    @discardableResult func stratifyScopes(_ scope: Scope) -> Int {
        print("->entering scope \(currentScopeIndex + 1)")
        scopes.append(scope)
        return scopes.count - 1
    }
    
    func exitScope() {
        print("<-exiting scope \(currentScopeIndex)")
        if currentScopeIndex > 0 {
            let exitingScope = scopes.removeLast()
            
            //Remove any statements left in `statementQueue`
            exitingScope.clearStatements()
            
            //Open up any addresses that no longer have pointers (`arc` == 0)
            for (_, varMeta) in exitingScope.references {
                store.decrementARCForInstanceTree(at: varMeta.address)
            }
            
            //Softly decrement `exitingScope`'s `this` reference, if it has one
            //(Softly because when an object is set to "this" during its "init" call, it has no pointers other than the "this" reference if the init scope. For normal calls with a "this" with no other pointers, the "this" will be in the parent/calling scope's unreferenced set, so it will be dealloc'd when said scope exits)
            if let thisAddress = exitingScope.this?.address {
                store.decrementARCForInstanceTree(at: thisAddress)
            }
            
            //Dealloc any initializer results that were unreferenced
            //(They wouldn't have ever been inserted into `exitingScope`'s `references`, so they won't be dealloc'd in above expression)
            //(If they have been inserted into `exitingScope`'s `references`, they would have been removed from the unreferenced set)
            for address in exitingScope.initializerResults {
                store.decrementARCForInstanceTree(at: address)
            }
        }
    }
    
    func popToScope(incuding includedIndex: Int) {
        //If `includedIndex` is not less than `scopes.count`, then nothing is done
        //(In otherwords, it's safe to call if one is unsure if scope at `includedIndex` exists still)
        print("poping through index \(includedIndex)")
        if includedIndex < scopes.count {
            for _ in (includedIndex..<scopes.count).reversed() {
                exitScope()
            }
        }
    }
    
    func popToRestrictedScope() {
        //Pops scopes until a restricted scope is found
        //Does not pop any scopes if the current scope is restricted
        while currentScope.scopeType != .restricted {
            print("ptrs")
            exitScope()
        }
    }
    
    func findYoungestScopeWith(_ identifier: String) -> Scope? {
        print("looking for scope containing \"\(identifier)\"")
        var scopeIndex = currentScopeIndex + 1
        
        repeat {
            scopeIndex -= 1
            print("checking scopes[\(scopeIndex)] (\(scopes[scopeIndex].scopeType))")
            if scopes[scopeIndex].references[identifier] != nil {
                return scopes[scopeIndex]
            }
        } while scopeIndex >= 0 && scopes[scopeIndex].scopeType == .enlightened
        
        return nil
    }
    
    
    //-----Variable Pointing Tasks-----
    
    func find(_ identifier: String) -> Int? {
        print("looking for \"\(identifier)\"")
        var scopeIndex = currentScopeIndex + 1
        
        repeat {
            scopeIndex -= 1
            print("looking in scopes[\(scopeIndex)] (\(scopes[scopeIndex].scopeType))")
            if let varMeta = scopes[scopeIndex].references[identifier] {
                print("found meta: \(varMeta)")
                return varMeta.address
            }
        } while scopeIndex >= 0 && scopes[scopeIndex].scopeType == .enlightened
        
        return nil
    }
    
    
    //-----ARC Tasks-----
    
    func removeInstanceTreeFromUnreferencedSet(at address: Int) {
        //Use recursively to parse `instance`'s properties and to remove each from unreferenced set
        
        currentScope.removeFromUnreferencedSet(address)
        
        let instance = store[address]!
        for (_, address) in instance.references {
            removeInstanceTreeFromUnreferencedSet(at: address)
        }
    }
    
    
    //-----Handling Classes-----
    
    func getClass(_ className: String) -> ClassDef? {
        return classes[className]
    }
    
    func getPublicMethFromClass(_ className: String, _ methName: String, _ paramSig: TupleType, _ isGlobal: Bool) -> MethodDef? {
        //Method must be public (can be a public super method)
        var classDef = getClass(className)
        
        while classDef != nil {
            for methDef in classDef!.methods {
                if methDef.identifier == methName && tupleTypeIsValid(methDef.signature.paramTypes, paramSig) && methDef.isGlobal == isGlobal && !methDef.isPrivate {
                    return methDef
                }
            }
            
            if classDef!.superName != nil {
                classDef = getClass(classDef!.superName!)
            } else {
                classDef = nil
            }
        }
        
        return nil
    }
    
    func getVisibleMethFromClass(_ className: String, _ methName: String, _ paramSig: TupleType, _ isGlobal: Bool) -> MethodDef? {
        //Method can be private or public method defined in `className`, or any public super method
        var classDef = getClass(className)
        
        while classDef != nil {
            for methDef in classDef!.methods {
                if methDef.identifier == methName && tupleTypeIsValid(methDef.signature.paramTypes, paramSig) && methDef.isGlobal == isGlobal {
                    if classDef!.className == className || !methDef.isPrivate {
                        return methDef
                    }
                }
            }
            
            if classDef!.superName != nil {
                classDef = getClass(classDef!.superName!)
            } else {
                classDef = nil
            }
        }
        
        return nil
    }
    
    func classInherits(_ className: String, _ desiredSuperName: String) -> Bool {
        var classDef = getClass(className)!
        
        while let superName = classDef.superName {
            if superName == desiredSuperName {
                return true
            }
            
            classDef = getClass(superName)!
        }
        
        return false
    }
    
    func getProperty(_ className: String, _ desiredProp: String, _ isGlobal: Bool, _ mustBePublic: Bool) -> PropertyDef? {
        var classDef = getClass(className)
        
        while classDef != nil {
            for propDef in classDef!.properties {
                //Check privacy permissions
                if (mustBePublic && !propDef.isPrivate) || !mustBePublic {
                    //Check global status
                    if propDef.isGlobal == isGlobal {
                        //Check for id equality
                        if propDef.identifier == desiredProp {
                            return propDef
                        }
                    }
                }
            }
            
            if classDef!.superName != nil {
                classDef = getClass(classDef!.superName!)
            } else {
                classDef = nil
            }
        }
        
        return nil
    }
    
    
    //-----Handling Instance Initialization-----
    
    func initBlock(_ captures: [String: Int], _ paramNames: [String], _ paramType: TupleType, _ returnType: Type, _ body: StatementNode) -> BlockInstance {
        let address = store.alloc()
        let instance = BlockInstance(captures, paramNames, paramType, returnType, body, address)
        store[address] = instance
        
        currentScope.addToUnreferencedSet(address)
        
        return instance
    }
    
    func initBoolean(_ value: Bool) -> BooleanInstance {
        let address = store.alloc()
        let instance = BooleanInstance(value, address)
        store[address] = instance
        
        currentScope.addToUnreferencedSet(address)
        
        print("Init'd Bool \(value) @\(address)")
        
        return instance
    }
    
    func initInteger(_ value: Int) -> IntegerInstance {
        let address = store.alloc()
        let instance = IntegerInstance(value, address)
        store[address] = instance
        
        currentScope.addToUnreferencedSet(address)
        
        print("Init'd Int \(value) @\(address)")
        
        return instance
    }
    
    func initString(_ value: String) -> StringInstance {
        let address = store.alloc()
        let instance = StringInstance(value, address)
        store[address] = instance
        
        currentScope.addToUnreferencedSet(address)
        
        print("Init'd String \(value) @\(address)")
        
        return instance
    }
    
    func initObject(_ className: String) throws -> ObjectInstance {
        var currentClassName: String? = className
        var properties = [String: Int]()
        var classTree = [ClassDef]()
        
        //Initialization Part A (Initialize each property, starting with `className`)
        print("Part A")
        repeat {
            let classDef = getClass(currentClassName!)!
            
            let propScope = Scope(currentClassName!)
            stratifyScopes(propScope)
            
            for property in classDef.properties where !property.isGlobal {
                let propAddress = try evaluate(property.value).address
                
                if property.isPrivate {
                    let propID = "<" + classDef.className + ">" + property.identifier
                    properties[propID] = propAddress
                } else {
                    properties[property.identifier] = propAddress
                }
                
                /*//Put `propAddress` in external scope's unreferenced set IF it is in  `propScope`'s
                if propScope.unreferencedSetContains(propAddress) {
                    parentScope.addToUnreferencedSet(propAddress)
                    
                    //Remove `propAddress` from `propScope`'s unreferenced set so it won't be dealloc'd during scope exit
                    removeInstanceTreeFromUnreferencedSet(at: propAddress)
                }*/
                
                //Remove `propAddress` from `propScope`'s unreferenced set because `propAddress` IS referenced by the object being init'd
                removeInstanceTreeFromUnreferencedSet(at: propAddress)
            }
            
            exitScope()
            
            classTree.append(classDef)
            
            currentClassName = classDef.superName
        } while currentClassName != nil
        
        //Initialization Part B (Create object)
        print("Part B")
        let address = store.alloc()
        let object = ObjectInstance(ObjectType(className), address, properties)
        store[address] = object
        
        //Initialization Part C (Call each initializer starting with most "super")
        print("Part C")
        for classDef in classTree.reversed() {
            let initializer = classDef.initializer
            
            //Create initializer's scope
            let initScope = Scope(object, classDef.className)
            
            //Increment @ `object.address` twice
            //(Do this because (1) it is being referenced by `initScope`'s "this" reference, and also (2) since during the initializer call `object` has no other pointers, it will be dealloc'd when `initScope` exits, therefore, the context is figuratively holding on to the object being init'd so that it doesn't get dealloc'd for the reason above. Will be softly decremented @ `object.address` after initialization)
            store.incrementARCForInstanceTree(at: object.address, by: 2)
            
            //Push the scope into context and get its index
            let initScopeIndex = stratifyScopes(initScope)
            
            //Perform the initializer's statement
            try perform(initializer.body)
            
            //Get the instance returned from this action (should be Void)
            let resultInstance: Instance
            if let resultAddress = currentScope.resultPointer {
                resultInstance = store[resultAddress]!
            } else {
                resultInstance = voidInstance
            }
            
            //Strip/Exit all remaining scopes created during action
            popToScope(incuding: initScopeIndex)
            
            //Softly decrement @ `object.address` to counter increment above
            store.softlyDecrementARCForInstanceTree(at: object.address)
            
            //Ensure that Void was returned
            if resultInstance.type.type != .void {
                fatalError("Returned instance from initializer")
                //TODO: expect return this
            }
        }
        
        print("Init'd object of type \(object.type)")
        
        currentScope.addToUnreferencedSet(address)
        
        return object
    }
    
    
    //-----Handling Type Checking-----
    
    func typeIsValid(_ actual: Type, _ expected: Type) -> Bool {
        if actual.type != expected.type {
            return false
        }
        
        switch actual.type {
        case .block: return blockTypeIsValid(actual as! BlockType, expected as! BlockType)
        case .object: return objectTypeIsValid(actual as! ObjectType, expected as! ObjectType)
        case .tuple: return tupleTypeIsValid(actual as! TupleType, expected as! TupleType)
        case .void: return true
        }
    }
        
    func blockTypeIsValid(_ actual: BlockType, _ expected: BlockType) -> Bool {
        return tupleTypeIsValid(actual.paramTypes, expected.paramTypes) && typeIsValid(actual.returnType, expected.returnType)
    }
    
    func objectTypeIsValid(_ actual: ObjectType, _ expected: ObjectType) -> Bool {
        return actual.className == expected.className || classInherits(actual.className, expected.className)
    }
    
    func tupleTypeIsValid(_ actual: TupleType, _ expected: TupleType) -> Bool {
        if actual.memberTypes.count != expected.memberTypes.count {
            return false
        }
        
        for (i, type) in actual.memberTypes.enumerated() {
            if !typeIsValid(type, expected.memberTypes[i]) {
                return false
            }
        }
        
        return true
    }
    
}

