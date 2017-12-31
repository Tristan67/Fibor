//
//  Context+Injector.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/14/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum InjectorError: Error {
    case redefinedClass(className: String)
    case extendedUndefinedClass(className: String)
}


extension Context {
    
    func injectClass(_ classDef: ClassDef) throws {
        if classes[classDef.className] == nil {
            classes[classDef.className] = classDef
            
            //Add global properties to `globalScope`
            for property in classDef.properties where property.isGlobal {
                let globalPropertyName = classDef.className + "." + property.identifier
                print("init'ing \"\(globalPropertyName)\"")
                let instance = try evaluate(property.value)
                let varMeta = VarMeta(instance.address, property.type)
                globalScope.declare(globalPropertyName, with: varMeta)
                store.incrementARCForInstanceTree(at: instance.address)
            }
            
        } else {
            throw InjectorError.redefinedClass(className: classDef.className)
        }
    }
    
    func injectExtension(_ extDef: ExtensionDef) throws {
        if let classDef = classes[extDef.className] {
            //Append Methods
            for method in extDef.methods {
                classDef.methods.append(method)
            }
            
            //Append Properties
            for property in extDef.properties {
                classDef.properties.append(property)
                
                //Add global properties to `globalScope`
                if property.isGlobal {
                    let globalPropertyName = classDef.className + "." + property.identifier
                    let instance = try evaluate(property.value)
                    let varMeta = VarMeta(instance.address, property.type)
                    globalScope.declare(globalPropertyName, with: varMeta)
                    store.incrementARCForInstanceTree(at: instance.address)
                }
            }
            
        } else {
            throw InjectorError.extendedUndefinedClass(className: extDef.className)
        }
    }
    
}

