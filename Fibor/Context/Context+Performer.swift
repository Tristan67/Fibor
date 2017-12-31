//
//  Context+Performer.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/14/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum PerformerError: Error {
    case redeclaredReferenceIdentifier(identifier: String)
    case declarationTypeAndValueDoNotMatch(expectedType: Type, valueType: Type)
    case ifConditionNotBooleanType
    case whileConditionNotBooleanType
}


extension Context {
    
    func perform(_ statement: StatementNode) throws {
        
        switch statement.stType {
        case .declaration: try performDeclaration(statement as! DeclarationSt)
        case .doSt: try performDo(statement as! DoSt)
        case .group: try performGroup(statement as! GroupSt)
        case .ifElse: try performIfElse(statement as! IfElseSt)
        case .implicitReturn: performImplicitReturn()
        case .returnSt: try performReturn(statement as! ReturnSt)
        case .whileLoop: try performWhile(statement as! WhileSt)
        //default: fatalError("Attempted to perform unknown statement type: \(statement.stType)") //Temporary
        }
        
    }
    
    private func performDeclaration(_ declaration: DeclarationSt) throws {
        if currentScope[declaration.identifier] != nil {
            throw PerformerError.redeclaredReferenceIdentifier(identifier: declaration.identifier)
        }
        
        let value = try evaluate(declaration.value)
        
        if !typeIsValid(value.type, declaration.type) {
            throw PerformerError.declarationTypeAndValueDoNotMatch(expectedType: declaration.type, valueType: value.type)
        }
        
        let varMeta = VarMeta(value.address, declaration.type)
        currentScope.declare(declaration.identifier, with: varMeta)
        store.incrementARCForInstanceTree(at: varMeta.address)
        
        //Remove instance at `value.address` from unreferencedSet IF it is in unreferencedSet
        //(because it IS referenced now)
        if currentScope.unreferencedSetContains(value.address) {
            removeInstanceTreeFromUnreferencedSet(at: value.address)
        }
    }
    
    private func performDo(_ discardable: DoSt) throws {
        //TODO: Immediately deinit result
        _ = try evaluate(discardable.expression)
    }
    
    private func performGroup(_ group: GroupSt) throws {
        //Create an enlightened scope
        let groupScope = Scope(.enlightened)
        
        //Append statements to `groupScope`'s `statementQueue`
        groupScope.pushStatements(group.statements)
        
        //Append `groupScope`
        let scopeIndex = stratifyScopes(groupScope)
        
        //Perform `groupScope`'s statements
        while let statement = groupScope.nextStatement() {
            try perform(statement)
        }
        
        //Remove enlightened scope added above
        popToScope(incuding: scopeIndex)
    }
    
    private func performIfElse(_ ifElse: IfElseSt) throws {
        let conditionInstance = try evaluate(ifElse.condition)
        
        if conditionInstance.type.type != .object {
            throw PerformerError.ifConditionNotBooleanType
        } else if (conditionInstance.type as! ObjectType).className != BaseDataType.boolean.rawValue {
            throw PerformerError.ifConditionNotBooleanType
        }
        
        if (conditionInstance as! BooleanInstance).value {
            try perform(ifElse.thenStatement)
        } else if ifElse.elseStatement != nil {
            try perform(ifElse.elseStatement!)
        }
    }
    
    private func performImplicitReturn() {
        //Pop to the scope that this return statement returns from
        popToRestrictedScope()
        
        //Set (the now) current scope's `resultPointer` to void's address
        currentScope.resultPointer = voidInstance.address
        
        print("implicit return")
    }
    
    private func performReturn(_ returnSt: ReturnSt) throws {
        //Get the instance to return
        let returnResultAddress = (try evaluate(returnSt.value)).address
        var unreferencedQ = false
        
        //Remove the instance from `currentScope`'s unreferenced set if it's in it
        //(This keeps it from being deinit'd while exiting scopes to the calling scope)
        if currentScope.unreferencedSetContains(returnResultAddress) {
            removeInstanceTreeFromUnreferencedSet(at: returnResultAddress)
            unreferencedQ = true
        }
        
        //Increment the result's ARC
        //(This also keeps it from being deinit'd while exiting scopes to the calling scope)
        //(Will be "softly" decremented later to counter this increment)
        store.incrementARCForInstanceTree(at: returnResultAddress)
        
        //Pop to the scope that this return statement returns from
        popToRestrictedScope()
        
        //Set (the now) current scope's `resultPointer` to returnResultAddress
        print("explicit return @\(returnResultAddress)")
        currentScope.resultPointer = returnResultAddress
        
        //Place `returnResultAddress` back in unreferenced set if it was there in former scope
        if unreferencedQ {
            currentScope.addToUnreferencedSet(returnResultAddress)
        }
        
        //Softly decrement `returnResultAddress`
        store.softlyDecrementARCForInstanceTree(at: returnResultAddress)
    }
    
    private func performWhile(_ whileLoop: WhileSt) throws {
        var conditionInstance: Instance
        
        while true {
            conditionInstance = try evaluate(whileLoop.condition)
            if conditionInstance.type.type != .object {
                throw PerformerError.whileConditionNotBooleanType
            } else if (conditionInstance.type as! ObjectType).className != BaseDataType.boolean.rawValue {
                throw PerformerError.whileConditionNotBooleanType
            }
            
            if (conditionInstance as! BooleanInstance).value {
                try perform(whileLoop.statement)
            } else {
                break
            }
        }
    }
    
}

