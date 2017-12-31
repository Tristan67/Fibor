//
//  Feed.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class Feed {
    
    private(set) var sourceCode: String
    private(set) var sourceLength: Int
    private(set) var position = 0
    private(set) var line = 0
    private(set) var column = 0
    
    
    init(_ source: String) {
        self.sourceCode = source
        self.sourceLength = source.count
    }
    
    
    @discardableResult func next() -> String? {
        if position < sourceLength {
            let symbol = sourceCode[position]
            
            if symbol == "\n" {
                line += 1
                column = 0
            } else {
                column += 1
            }
            
            position += 1
            
            return symbol
        }
        
        return nil
    }
    
    func peek() -> String? {
        if position < sourceLength {
            return sourceCode[position]
        }
        
        return nil
    }
    
}

