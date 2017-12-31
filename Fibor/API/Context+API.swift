//
//  Context+API.swift
//  Fibor
//
//  Created by Tristan Barnes on 12/22/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


extension Context {
    
    //-----Type Methods-----
    
    public static func makeDefault() -> Context {
        let context = Context()
        
        //Add Base Classes
        try! context.injectClass(ObjectClass())
        try! context.injectClass(BooleanClass())
        try! context.injectClass(IntegerClass())
        try! context.injectClass(StringClass())
        
        return context
    }
    
    
    //-----Instance Methods-----
    
    public func inject(_ definitionsSource: String) throws {
        let feed = Feed(definitionsSource)
        let lexer = Lexer(feed)
        let parser = Parser(lexer)
        
        while lexer.peek().type != .endOfSource {
            let def = try parser.parseDefinition()
            
            if def.defType == .classDef {
                let classDef = def as! ClassDef
                try injectClass(classDef)
                //print("Added class: \(classDef.className)")
                
            } else if def.defType == .extensionDef {
                let extensionDef = def as! ExtensionDef
                try injectExtension(extensionDef)
                //print("Extended class: \(extensionDef.className)")
                
            } else {
                //TODO: Implement "unexpected definition" handling/throwing
            }
        }
    }
    
    public func perform(_ statementsSource: String) throws {
        let feed = Feed(statementsSource)
        let lexer = Lexer(feed)
        let parser = Parser(lexer)
        
        while lexer.peek().type != .endOfSource {
            
            let statement = try parser.parseStatement()
            
            try perform(statement)
        }
    }
    
    
    //-----Temporary for Testing-----
    
    public func getStoreRepresentation() -> String {
        return "\(store)"
    }
    
}

