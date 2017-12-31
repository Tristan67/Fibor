//
//  Scope.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/19/17 (Major revision on 10/7/2017).
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum ScopeType {
    case enlightened
    case restricted
}


struct VarMeta {
    
    var address: Int
    let dataType: Type
    
    init(_ address: Int, _ dataType: Type) {
        self.address = address
        self.dataType = dataType
    }
    
}


class Scope {
    
    let this: ObjectInstance?
    let scopeType: ScopeType
    let privateAccessNameType: String?
    var references = [String: VarMeta]() //TODO: Make identifier part of `VarMeta` and use `VarMeta` as key and just address as value
    var initializerResults = Set<Int>()
    var resultPointer: Int?
    var statementQueue = [StatementNode]()
    
    init(_ this: ObjectInstance, _ privateAccessNameType: String) {
        self.this = this
        self.scopeType = .restricted
        self.privateAccessNameType = privateAccessNameType
    }
    
    init(_ privateAccessNameType: String) {
        self.this = nil
        self.scopeType = .restricted
        self.privateAccessNameType = privateAccessNameType
    }
    
    init(_ scopeType: ScopeType) {
        self.this = nil
        self.scopeType = scopeType
        self.privateAccessNameType = nil
    }
    
    func point(_ identifier: String, to address: Int) {
        references[identifier]!.address = address
    }
    
    subscript(identifier: String) -> VarMeta? {
        return references[identifier]
    }
    
    func declare(_ identifier: String, with varMeta: VarMeta) {
        references[identifier] = varMeta
    }
    
    func unreferencedSetContains(_ address: Int) -> Bool {
        return initializerResults.contains(address)
    }
    
    func addToUnreferencedSet(_ address: Int) {
        initializerResults.insert(address)
    }
    
    func removeFromUnreferencedSet(_ address: Int) {
        initializerResults.remove(address)
    }
    
    func pushStatement(_ statement: StatementNode) {
        statementQueue.append(statement)
    }
    
    func pushStatements(_ statements: [StatementNode]) {
        for i in 0..<statements.count {
            statementQueue.append(statements[i])
        }
    }
    
    func nextStatement() -> StatementNode? {
        return statementQueue.isEmpty ? nil : statementQueue.removeFirst()
    }
    
    func clearStatements() {
        statementQueue.removeAll()
    }
    
}

