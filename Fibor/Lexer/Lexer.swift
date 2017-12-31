//
//  Lexer.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/2/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation

class Lexer {
    
    
    //-----Instance Properties-----
    
    private let feed: Feed
    
    private(set) var buffer: Token?
    
    
    //-----Initializers-----
    
    init(_ feed: Feed) {
        self.feed = feed
    }
    
    
    //-----API-----
    
    /*func tokenize() -> [Token] {
        var tokens = [Token]()
        var token: Token
        
        repeat {
            token = next()
            tokens.append(token)
        } while token.type != .endOfSource
        
        return tokens
    }*/
    
    func next() -> Token {
        
        if let token = buffer {
            buffer = nil
            return token
        }
        
        skipWhitespaces()
        
        if feed.peek() == nil {
            return Token(.endOfSource, nil, feed.line, feed.column)
        }
        
        let symbol = feed.peek()!
        
        if isStartOfKeywordOrIdentifier(symbol) {
            return recognizeKeywordOrIdentifier()
        }
        
        if symbol.isDelimiter() {
            return recognizeDelimiter()
        }
        
        if isStartOfIntegerLiteral(symbol) {
            return recognizeIntegerLiteral()
        }
        
        if isStartOfOperator(symbol) {
            return recognizeOperator()
        }
        
        if symbol.isDot() {
            return recognizeDot()
        }
        
        if symbol == "\"" {
            return recognizeStringLiteral()
        }
        
        /*if symbol == "#" {
            skipUntilNewline()
            skipNewline()
            return next()
        }*/
        
        if symbol == "@" {
            return recognizeGlobal()
        }
        
        return Token(.unrecognized, symbol, feed.line, feed.column)
        
    }
    
    
    func peek() -> Token {
        let token = next()
        if buffer == nil {
            buffer = token
        }
        return token
    }
    
    
    //-----Recognizing Globals-----
    
    func recognizeGlobal() -> Token {
        feed.next() //Skip `@`
        
        let line = feed.line
        let column = feed.column
        
        var id = feed.next()!
        
        if feed.peek() != nil && feed.peek()!.isAlphaChar() {
            repeat {
                id += feed.next()!
            } while feed.peek() != nil && feed.peek()!.isAlphaChar()
            
            return Token(.global, id, line, column)
        }
        
        return Token(.unrecognized, id, line, column)
    }
    
    
    //-----Recognizer Methods-----
    
    func recognizeDelimiter() -> Token {
        let symbol = feed.peek()!
        
        let token = Token(.delimiter, symbol, feed.line, feed.column)
        
        feed.next()
        
        return token
    }
    
    func recognizeDot() -> Token {
        feed.next()
        return Token(.dot, ".", feed.line, feed.column)
    }
    
    
    //-----Recognizing Integer Literals-----
    
    func isStartOfIntegerLiteral(_ symbol: String) -> Bool {
        return symbol.isDigit()
    }
    
    func recognizeIntegerLiteral() -> Token {
        let line = feed.line
        let column = feed.column
        
        var integer = ""
        
        while let symbol = feed.peek(), symbol.isDigit() {
            integer += feed.next()!
        }
        
        let token = Token(.integerLiteral, integer, line, column)
        
        return token
        
    }
    
    
    //-----Recognizing Keywords or Identifiers-----
    
    func isStartOfKeywordOrIdentifier(_ symbol: String) -> Bool {
        return symbol.isAlphaChar()
    }
    
    func recognizeKeywordOrIdentifier() -> Token {
        let line = feed.line
        let column = feed.column
        
        var word = ""
        
        while let symbol = feed.peek(), symbol.isAlphaChar() {
            word += feed.next()!
        }
        
        if let _ = KeywordType(rawValue: word) {
            return Token(.keyword, word, line, column)
        } else {
            return Token(.identifier, word, line, column)
        }
    }
    
    
    //-----Recognizing Operators-----
    
    func isStartOfOperator(_ symbol: String) -> Bool {
        return symbol.isOperatorChar()
    }
    
    func recognizeOperator() -> Token {
        let line = feed.line
        let column = feed.column
        
        var op = ""
        
        while let symbol = feed.peek(), symbol.isOperatorChar() {
            op += feed.next()!
        }
        
        return Token(.op, op, line, column)
    }
    
    
    //-----Recognizing String Literals-----
    
    func recognizeStringLiteral() -> Token {
        let line = feed.line
        let column = feed.column
        
        feed.next()
        
        var strLit = ""
        
        while let peek = feed.peek(), peek != "\"" {
            strLit += feed.next()!
        }
        feed.next()
        
        return Token(.stringLiteral, strLit, line, column)
    }
    
    
    //-----Helpers-----
    
    func skipWhitespaces() {
        while let symbol = feed.peek(), symbol.isWhitespace() || symbol.isNewline() {
            feed.next()
        }
    }
    
    func skipNewline() {
        if let symbol = feed.peek(), symbol.isNewline() {
            feed.next()
        }
    }
    
    func skipUntilNewline() {
        while let symbol = feed.peek(), !symbol.isNewline() {
            feed.next()
        }
    }
    
}

