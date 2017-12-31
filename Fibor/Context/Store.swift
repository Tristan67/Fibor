//
//  Store.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/15/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class Store: CustomDebugStringConvertible {
    
    private var internalStore = [Int: Instance]()
    
    
    //-----Getting/Setting Instances-----
    
    func get(_ address: Int) -> Instance? {
        return internalStore[address]
    }
    
    func set(_ instance: Instance, at address: Int) {
        internalStore[address] = instance
    }
    
    subscript(address: Int) -> Instance? {
        get {
            return get(address)
        }
        set {
            if let instance = newValue {
                set(instance, at: address)
            } else {
                dealloc(address)
            }
        }
    }
    
    func replaceInstance(at address: Int, with newInstance: Instance) {
        let oldInstance = internalStore[address]!
        newInstance.references = oldInstance.references
        newInstance.arc = oldInstance.arc
        internalStore[address] = newInstance
    }
    
    
    //-----Handling (De)Allocation-----
    
    func alloc() -> Int {
        var address = 0
        //While less than `store.count - 1` because store[-1] holds void instance
        while address < internalStore.count - 1 && internalStore[address] != nil {
            address += 1
        }
        
        return address
    }
    
    private func dealloc(_ address: Int) {
        print("deallocing @\(address)")
        internalStore.removeValue(forKey: address)
    }
    
    
    //-----Handling ARC-----
    
    func incrementARCForInstanceTree(at address: Int) {
        //Use recursively to parse `instance`'s references and to increment `arc` on each
        
        let instance = internalStore[address]!
        
        instance.arc += 1
        for (_, referenceAddress) in instance.references {
            incrementARCForInstanceTree(at: referenceAddress)
        }
    }
    
    func decrementARCForInstanceTree(at address: Int) {
        //Use recursively to parse `instances`'s references
        //Dealloc the ones with an `arc` of zero
        
        let instance = internalStore[address]!
        
        //Parse reference instances
        for (_, referenceAddress) in instance.references {
            decrementARCForInstanceTree(at: referenceAddress)
        }
        
        //Dealloc `instance` if `arc` == 0 or will be 0; Just decrement otherwise
        if instance.arc < 2 {
            dealloc(address)
        } else {
            instance.arc -= 1
        }
    }
    
    func softlyDecrementARCForInstanceTree(at address: Int) {
        //Use recursively to parse `instances`'s references
        //Do NOT dealloc the ones with an `arc` of zero
        
        let instance = internalStore[address]!
        
        //Parse reference instances
        for (_, referenceAddress) in instance.references {
            softlyDecrementARCForInstanceTree(at: referenceAddress)
        }
        
        //Decrement if `arc` > 0; Otherwise, leave `arc` at zero
        if instance.arc > 0 {
            instance.arc -= 1
        }
    }
    
    func incrementARCForInstanceTree(at address: Int, by dif: UInt) {
        //Use recursively to parse `instance`'s references and to increment `arc` on each
        
        let instance = internalStore[address]!
        
        instance.arc += dif
        for (_, referenceAddress) in instance.references {
            incrementARCForInstanceTree(at: referenceAddress, by: dif)
        }
    }
    
    func decrementARCForInstanceTree(at address: Int, by dif: UInt) {
        //Use recursively to parse `instances`'s references
        //Dealloc the ones with an `arc` of zero
        
        let instance = internalStore[address]!
        
        //Parse reference instances
        for (_, referenceAddress) in instance.references {
            decrementARCForInstanceTree(at: referenceAddress, by: dif)
        }
        
        //Dealloc `instance` if `arc` == 0 or will be 0; Just decrement otherwise
        if instance.arc <= dif {
            dealloc(address)
        } else {
            instance.arc -= dif
        }
    }
    
    
    //-----Debugging-----
    
    var debugDescription: String {
        var str = ""
        
        for (key, value) in internalStore {
            str += "\(key): \(value)\n\n"
        }
        
        return str
    }
    
    var count: Int {
        return internalStore.count
    }
    
}

