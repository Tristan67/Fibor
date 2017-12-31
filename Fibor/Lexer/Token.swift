//
//  Token.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


enum KeywordType: String {
    case classKey = "class"
    case doKey = "do"
    case elseKey = "else"
    case extensionKey = "extension"
    case falseKey = "false"
    case globalKey = "global"
    case ifKey = "if"
    case infixKey = "infix"
    case initKey = "init"
    case methKey = "meth"
    case postfixKey = "postfix"
    case prefixKey = "prefix"
    case privateKey = "private"
    case propKey = "prop"
    case returnKey = "return"
    case superKey = "super"
    case thisKey = "this"
    case trueKey = "true"
    case varKey = "var"
    case whileKey = "while"
}


enum TokenType {
    case delimiter
    case dot
    case global
    //case grouper
    case identifier
    case integerLiteral
    case keyword
    case op
    case stringLiteral
    
    case endOfSource
    case unrecognized
}


class Token {
    
    let type: TokenType
    let value: String!
    let line: Int
    let column: Int
    
    init(_ type: TokenType, _ value: String!, _ line: Int, _ column: Int) {
        self.type = type
        self.value = value
        self.line = line
        self.column = column
    }
    
    /*static func ~=(_ lhs: Token, _ rhs: Token) -> Bool {
        return lhs.type == rhs.type && lhs.value == rhs.value
    }*/
}

