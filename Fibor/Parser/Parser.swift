//
//  Parser.swift
//  Fibor
//
//  Created by Tristan Barnes on 9/3/17 (Major revision on 10/6-7/2017).
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


let ASSIGNMENT_OP = "="
let RETURN_OP = "->"
let BLOCK_LITERAL_OP = "^"
let IN_OP_PREFIX = "infix_"
let POST_OP_PREFIX = "postfix_"
let PRE_OP_PREFIX = "prefix_"
let VOID_SYMBOL = "#"


enum ParserError: Error {
    case foundUnrecognizedToken(token: Token)
    case encounteredUnexpectedToken(token: Token)
    case methodDefinitionHasAmbiguousParameters(parameter: String)
    case blockLiteralHasAmbiguousCaptureNames(name: String)
    case blockLiteralHasAmbiguousParameters(name: String)
    case blockLiteralHasMatchingCaptureAndParameterName(name: String)
    case modifiedInitializer(className: String)
    case multipleInitializers(className: String)
    case noInitializer(className: String)
}


class Parser {
    
    //-----Instance Properties-----
    
    private let lexer: Lexer
    
    
    //-----Initializers-----
    
    init(_ lexer: Lexer) {
        self.lexer = lexer
    }
    
    
    //-----Parsing Expressions-----
    
    func parseExpression() throws -> ExpressionNode {
        var peek = lexer.peek()
        
        if peek.type == .unrecognized {
            throw ParserError.foundUnrecognizedToken(token: peek)
        }
        
        //Parse root expression
        var expression: ExpressionNode
        
        if peek.type == .delimiter && peek.value == "(" {
            try expectTokenOfType(.delimiter, withValue: "(")
            expression = try parseExpression()
            try expectTokenOfType(.delimiter, withValue: ")")
            peek = lexer.peek()
            
        } else if peek.type == .global {
            let globalName = try expectTokenOfType(.global).value!
            peek = lexer.peek()
            
            if peek.type == .dot {
                expression = try parseGlobalPropertyInspection(globalName)
            } else if peek.type == .identifier {
                expression = try parseGlobalCall(globalName)
            } else if peek.type == .keyword && peek.value == KeywordType.initKey.rawValue {
                expression = try parseInitialization(globalName)
            } else {
                throw ParserError.encounteredUnexpectedToken(token: peek)
            }
            
        } else if peek.type == .identifier {
            expression = try parseReference()
            
        } else if peek.type == .integerLiteral {
            expression = try parseIntegerLiteral()
            
        } else if peek.type == .keyword {
            switch KeywordType(rawValue: peek.value!)! {
            case .falseKey:
                try expectTokenOfType(.keyword, withValue: KeywordType.falseKey.rawValue)
                expression = BooleanLiteralExp(false)
            case .superKey: expression = try parseSuperCall()
            case .thisKey:
                try expectTokenOfType(.keyword, withValue: KeywordType.thisKey.rawValue)
                expression = ThisLiteralExp()
            case .trueKey:
                try expectTokenOfType(.keyword, withValue: KeywordType.trueKey.rawValue)
                expression = BooleanLiteralExp(true)
            default: throw ParserError.encounteredUnexpectedToken(token: peek)
            }
            
        } else if peek.type == .op {
            if peek.value! == BLOCK_LITERAL_OP {
                expression = try parseBlockLiteral()
            } else {
                expression = try parsePrefixOperation()
            }
            
        } else if peek.type == .stringLiteral {
            expression = try parseStringLiteral()
            
        } else {
            throw ParserError.encounteredUnexpectedToken(token: peek)
        }
        
        return try tryParsingExtendedExpression(expression)
    }
    
    private func isExpressionStart() -> Bool {
        let peek = lexer.peek()
        
        if peek.type == .delimiter && peek.value == "(" {
            return true
            
        } else if peek.type == .global {
            return true
            
        } else if peek.type == .identifier {
            return true
            
        } else if peek.type == .integerLiteral {
            return true
            
        } else if peek.type == .keyword {
            switch KeywordType(rawValue: peek.value!)! {
            case .falseKey, .superKey, .thisKey, .trueKey: return true
            default: return false
            }
            
        } else if peek.type == .op {
            return true
            
        } else if peek.type == .stringLiteral {
            return true
            
        }
        
        return false
    }
    
    private func parseBlockLiteral() throws -> BlockLiteralExp {
        try expectTokenOfType(.op, withValue: BLOCK_LITERAL_OP)
        
        //Parse captured list (names and values)
        var captures = [String: ExpressionNode]()
        if lexer.peek().type == .delimiter && lexer.peek().value == "[" {
            try expectTokenOfType(.delimiter, withValue: "[")
            
            try deliminate(.delimiter, ",", .delimiter, "]", {
                let captureName = try expectTokenOfType(.identifier).value!
                
                if captures[captureName] != nil {
                    throw ParserError.blockLiteralHasAmbiguousCaptureNames(name: captureName)
                } else {
                    captures[captureName] = try parseExpression()
                }
            }, nil)
            
            try expectTokenOfType(.delimiter, withValue: "]")
        }
        
        //Parse parameters (names and types)
        var parameterNames = [String]()
        var parameterTypes = [Type]()
        if lexer.peek().type == .delimiter && lexer.peek().value == "(" {
            try expectTokenOfType(.delimiter, withValue: "(")
        
            try deliminate(.delimiter, ",", .delimiter, ")", {
                let parameterName = try expectTokenOfType(.identifier).value!
                
                if parameterNames.contains(parameterName) {
                    throw ParserError.blockLiteralHasAmbiguousParameters(name: parameterName)
                } else if captures[parameterName] != nil {
                    throw ParserError.blockLiteralHasMatchingCaptureAndParameterName(name: parameterName)
                } else {
                    parameterNames.append(parameterName)
                    parameterTypes.append(try parseType())
                }
            }, nil)
            
            try expectTokenOfType(.delimiter, withValue: ")")
        }
        
        //Parse return type
        let returnType: Type
        if lexer.peek().type == .op && lexer.peek().value == RETURN_OP {
            try expectTokenOfType(.op, withValue: RETURN_OP)
            returnType = try parseType()
        } else {
            returnType = VoidType()
        }
        
        //Parse statement
        var statement = try parseStatement()
        if statement.stType != .returnSt {
            //Ensure that there is an implicit return at the end
            statement = GroupSt([statement, ImplicitReturnSt()])
        }
        
        return BlockLiteralExp(captures, parameterNames, BlockType(TupleType(parameterTypes), returnType), statement)
    }
    
    private func parseGlobalCall(_ globalName: String) throws -> GlobalCallExp {
        let methodName = try expectTokenOfType(.identifier).value!
        var arguments = [ExpressionNode]()
        
        //Parse arguments
        if lexer.peek().type == .op && lexer.peek().value == ":" {
            try expectTokenOfType(.op, withValue: ":")
            arguments = try helpParseCallArguments()
        }
        
        return GlobalCallExp(globalName, methodName, arguments)
    }
    
    private func parseGlobalPropertyInspection(_ globalName: String) throws -> GlobalPropertyInspectionExp {
        try expectTokenOfType(.dot)
        return GlobalPropertyInspectionExp(globalName, try expectTokenOfType(.identifier).value!)
    }
    
    private func parseInitialization(_ dataType: String) throws -> InitializationExp {
        try expectTokenOfType(.keyword, withValue: KeywordType.initKey.rawValue)
        return InitializationExp(dataType)
    }
    
    private func parseIntegerLiteral() throws -> IntegerLiteralExp {
        let valueStr = try expectTokenOfType(.integerLiteral).value!
        return IntegerLiteralExp(Int(valueStr)!)
    }
    
    private func parsePrefixOperation() throws -> CallExp {
        let op = try expectTokenOfType(.op).value!
        return CallExp(try parseExpression(), PRE_OP_PREFIX + op, [])
    }
    
    private func parseReference() throws -> ReferenceExp {
        return ReferenceExp(try expectTokenOfType(.identifier).value!)
    }
    
    private func parseStringLiteral() throws -> StringLiteralExp {
        return StringLiteralExp(try expectTokenOfType(.stringLiteral).value!)
    }
    
    private func parseSuperCall() throws -> SuperCallExp {
        try expectTokenOfType(.keyword, withValue: KeywordType.superKey.rawValue)
        
        let methodName = try expectTokenOfType(.identifier).value!
        var arguments = [ExpressionNode]()
        
        //Parse arguments
        if lexer.peek().type == .op && lexer.peek().value == ":" {
            try expectTokenOfType(.op, withValue: ":")
            arguments = try helpParseCallArguments()
        }
        
        return SuperCallExp(methodName, arguments)
    }
    
    
    //-----Parsing Expression Calls Helpers-----
    
    private func helpParseCallArguments() throws -> [ExpressionNode] {
        var arguments = [ExpressionNode]()
        
        arguments.append(try parseExpression())
        
        while lexer.peek().type == .delimiter && lexer.peek().value == "," {
            try expectTokenOfType(.delimiter, withValue: ",")
            arguments.append(try parseExpression())
        }
        
        return arguments
    }
    
    
    //-----Trying to parse extended expressions-----
    
    private func tryParsingExtendedExpression(_ root: ExpressionNode) throws -> ExpressionNode {
        var didExtendFlag = false
        var expression = root
        let peek = lexer.peek()
        
        if peek.type == .delimiter && peek.value == "(" {
            expression = try parseInvocation(root)
            didExtendFlag = true
            
        } else if peek.type == .dot {
            expression = try parsePropertyInspection(root)
            didExtendFlag = true
            
        } else if peek.type == .identifier {
            expression = try parseCall(root)
            didExtendFlag = true
            
        } else if peek.type == .op {
            let op = try expectTokenOfType(.op).value!
            
            if isExpressionStart() {
                //Parse as infix
                if op == ASSIGNMENT_OP {
                    expression = AssignmentExp(root, try parseExpression())
                } else {
                    expression = CallExp(root, IN_OP_PREFIX + op, [try parseExpression()])
                }
                
            } else {
                //Parse as postfix
                expression = CallExp(root, POST_OP_PREFIX + op, [])
            }
            
            didExtendFlag = true
        }
        
        if didExtendFlag {
            return try tryParsingExtendedExpression(expression)
        } else {
            return root
        }
    }
    
    private func parseCall(_ root: ExpressionNode) throws -> CallExp {
        let methodName = try expectTokenOfType(.identifier).value!
        var arguments = [ExpressionNode]()
        
        //Parse arguments
        if lexer.peek().type == .op && lexer.peek().value == ":" {
            try expectTokenOfType(.op, withValue: ":")
            arguments = try helpParseCallArguments()
        }
        
        return CallExp(root, methodName, arguments)
    }
    
    private func parseInvocation(_ root: ExpressionNode) throws -> BlockInvocationExp {
        var arguments = [ExpressionNode]()
        
        //Parse arguments
        try expectTokenOfType(.delimiter, withValue: "(")
        
        try deliminate(.delimiter, ",", .delimiter, ")", {
            arguments.append(try parseExpression())
        }, nil)
        
        try expectTokenOfType(.delimiter, withValue: ")")
        
        return BlockInvocationExp(root, arguments)
    }
    
    private func parsePropertyInspection(_ root: ExpressionNode) throws -> ExpressionNode {
        try expectTokenOfType(.dot)
        let propertyName = try expectTokenOfType(.identifier).value!
        return PropertyInspectionExp(root, propertyName)
    }
    
    
    //-----Parsing Statements-----
    
    func parseStatement() throws -> StatementNode {
        let peek = lexer.peek()
        
        if peek.type == .unrecognized {
            throw ParserError.foundUnrecognizedToken(token: peek)
        }
        
        if peek.type == .keyword {
            switch KeywordType(rawValue: peek.value!)! {
            case .varKey: return try parseDeclaration()
            case .doKey: return try parseDo()
            case .ifKey: return try parseIfElse()
            case .returnKey: return try parseReturn()
            case .whileKey: return try parseWhile()
            default: throw ParserError.encounteredUnexpectedToken(token: peek)
            }
            
        } else if peek.type == .delimiter && peek.value == "{" {
            return try parseGroup()
        }
        
        throw ParserError.encounteredUnexpectedToken(token: peek)
    }
    
    private func parseDeclaration() throws -> DeclarationSt {
        try expectTokenOfType(.keyword, withValue: KeywordType.varKey.rawValue)
        let identifier = try expectTokenOfType(.identifier).value!
        let dataType = try parseType()
        try expectTokenOfType(.op, withValue: ASSIGNMENT_OP)
        return DeclarationSt(identifier, dataType, value: try parseExpression())
    }
    
    private func parseDo() throws -> DoSt {
        try expectTokenOfType(.keyword, withValue: KeywordType.doKey.rawValue)
        return DoSt(try parseExpression())
    }
    
    private func parseGroup() throws -> GroupSt {
        try expectTokenOfType(.delimiter, withValue: "{")
        var statements = [StatementNode]()
        var peek = lexer.peek()
        
        while peek.type != .delimiter && peek.value != "}" {
            statements.append(try parseStatement())
            peek = lexer.peek()
        }
        
        try expectTokenOfType(.delimiter, withValue: "}")
        
        return GroupSt(statements)
    }
    
    private func parseIfElse() throws -> IfElseSt {
        try expectTokenOfType(.keyword, withValue: KeywordType.ifKey.rawValue)
        let condition = try parseExpression()
        let thenStatement = try parseStatement()
        var elseStatement: StatementNode?
        
        if lexer.peek().type == .keyword && lexer.peek().value! == KeywordType.elseKey.rawValue {
            try expectTokenOfType(.keyword, withValue: KeywordType.elseKey.rawValue)
            elseStatement = try parseStatement()
        }
        
        return IfElseSt(condition, thenStatement, elseStatement: elseStatement)
    }
    
    private func parseReturn() throws -> ReturnSt {
        try expectTokenOfType(.keyword, withValue: KeywordType.returnKey.rawValue)
        if isExpressionStart() {
            return ReturnSt(try parseExpression())
        }
        //Return void implicitly
        return ReturnSt(NativeExp({ context in
            return context.voidInstance
        }))
    }
    
    private func parseWhile() throws -> WhileSt {
        try expectTokenOfType(.keyword, withValue: KeywordType.whileKey.rawValue)
        let condition = try parseExpression()
        return WhileSt(condition, try parseStatement())
    }
    
    
    //-----Parsing Definitions-----
    
    func parseDefinition() throws -> DefinitionNode {
        let peek = lexer.peek()
        
        if peek.type == .unrecognized {
            throw ParserError.foundUnrecognizedToken(token: peek)
        }
        
        if peek.type == .keyword && peek.value == KeywordType.classKey.rawValue {
            return try parseClass()
        } else if peek.type == .keyword && peek.value == KeywordType.extensionKey.rawValue {
            return try parseExtension()
        } else {
            throw ParserError.encounteredUnexpectedToken(token: peek)
        }
    }
    
    private func parseClass() throws -> ClassDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.classKey.rawValue)
        let className = try expectTokenOfType(.identifier).value!
        
        var peek = lexer.peek()
        
        var superClassName: String?
        if peek.type == .op && peek.value == ":" {
            try expectTokenOfType(.op, withValue: ":")
            superClassName = try expectTokenOfType(.identifier).value!
        }
        
        var initializer: InitializerDef?
        var methods = [MethodDef]()
        var properties = [PropertyDef]()
        
        try expectTokenOfType(.delimiter, withValue: "{")
        
        peek = lexer.peek()
        
        while peek.type != .delimiter && peek.value != "}" {
            var isGlobal = false
            var isPrivate = false
            
            peek = lexer.peek()
            
            if peek.type == .keyword && peek.value == KeywordType.globalKey.rawValue {
                try expectTokenOfType(.keyword, withValue: KeywordType.globalKey.rawValue)
                peek = lexer.peek()
                isGlobal = true
            }
            
            if peek.type == .keyword && peek.value == KeywordType.privateKey.rawValue {
                try expectTokenOfType(.keyword, withValue: KeywordType.privateKey.rawValue)
                peek = lexer.peek()
                isPrivate = true
            }
            
            switch KeywordType(rawValue: peek.value)! {
            case .infixKey: methods.append(try parseInfixOperator(isGlobal, isPrivate, className))
            case .initKey:
                if isGlobal || isPrivate {
                    throw ParserError.modifiedInitializer(className: className)
                }
                if initializer != nil {
                    throw ParserError.multipleInitializers(className: className)
                }
                initializer = try parseInitializer()
            case .methKey: methods.append(try parseMethod(isGlobal, isPrivate, className))
            case .postfixKey: methods.append(try parsePostfixOperator(isGlobal, isPrivate, className))
            case .prefixKey: methods.append(try parsePrefixOperator(isGlobal, isPrivate, className))
            case .propKey: properties.append(try parseProperty(isGlobal, isPrivate, className))
            default: throw ParserError.encounteredUnexpectedToken(token: peek)
            }
            
            peek = lexer.peek()
        }
        
        try expectTokenOfType(.delimiter, withValue: "}")
        
        if initializer == nil {
            throw ParserError.noInitializer(className: className)
        }
        
        return ClassDef(className, superClassName, initializer!, methods, properties)
    }
    
    private func parseExtension() throws -> ExtensionDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.extensionKey.rawValue)
        let className = try expectTokenOfType(.identifier).value!
        
        var methods = [MethodDef]()
        var properties = [PropertyDef]()
        
        try expectTokenOfType(.delimiter, withValue: "{")
        
        var peek = lexer.peek()
        
        while peek.type != .delimiter && peek.value != "}" {
            var isGlobal = false
            var isPrivate = false
            
            peek = lexer.peek()
            
            if peek.type == .keyword && peek.value == KeywordType.globalKey.rawValue {
                try expectTokenOfType(.keyword, withValue: KeywordType.globalKey.rawValue)
                peek = lexer.peek()
                isGlobal = true
            }
            
            if peek.type == .keyword && peek.value == KeywordType.privateKey.rawValue {
                try expectTokenOfType(.keyword, withValue: KeywordType.privateKey.rawValue)
                peek = lexer.peek()
                isPrivate = true
            }
            
            switch KeywordType(rawValue: peek.value)! {
            case .infixKey: methods.append(try parseInfixOperator(isGlobal, isPrivate, className))
            case .methKey: methods.append(try parseMethod(isGlobal, isPrivate, className))
            case .postfixKey: methods.append(try parsePostfixOperator(isGlobal, isPrivate, className))
            case .prefixKey: methods.append(try parsePrefixOperator(isGlobal, isPrivate, className))
            case .propKey: properties.append(try parseProperty(isGlobal, isPrivate, className))
            default: throw ParserError.encounteredUnexpectedToken(token: peek)
            }
            
            peek = lexer.peek()
        }
        
        try expectTokenOfType(.delimiter, withValue: "}")
        
        return ExtensionDef(className, methods, properties)
    }
    
    
    //-----Parsing Secondary Definitions-----
    
    private func parseInfixOperator(_ isGlobal: Bool, _ isPrivate: Bool, _ definedInClass: String) throws -> MethodDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.infixKey.rawValue)
        let op = try expectTokenOfType(.op).value!
        try expectTokenOfType(.delimiter, withValue: "(")
        let parameterName = try expectTokenOfType(.identifier).value!
        let parameterDataType = try parseType()
        try expectTokenOfType(.delimiter, withValue: ")")
        try expectTokenOfType(.op, withValue: RETURN_OP)
        let returnType = try parseType()
        
        //Parse statement
        var statement = try parseStatement()
        if statement.stType != .returnSt {
            //Ensure that there is an implicit return at the end
            statement = GroupSt([statement, ImplicitReturnSt()])
        }
        
        return MethodDef(isGlobal, isPrivate, IN_OP_PREFIX + op, [parameterName], BlockType(TupleType([parameterDataType]), returnType), definedInClass, statement)
    }
    
    private func parseInitializer() throws -> InitializerDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.initKey.rawValue)
        return InitializerDef(try parseStatement())
    }
    
    private func parseMethod(_ isGlobal: Bool, _ isPrivate: Bool, _ definedInClass: String) throws -> MethodDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.methKey.rawValue)
        let methodName = try expectTokenOfType(.identifier).value!
        var parameterNames = [String]()
        var parameterTypes = [Type]()
        
        //Parse parameters (names and types)
        try expectTokenOfType(.delimiter, withValue: "(")
        
        try deliminate(.delimiter, ",", .delimiter, ")", {
            let parameterName = try expectTokenOfType(.identifier).value!
            
            if parameterNames.contains(parameterName) {
                throw ParserError.methodDefinitionHasAmbiguousParameters(parameter: parameterName)
            } else {
                parameterNames.append(parameterName)
                parameterTypes.append(try parseType())
            }
        }, nil)
        
        try expectTokenOfType(.delimiter, withValue: ")")
        
        //Parse return type
        let returnType: Type
        if lexer.peek().type == .op && lexer.peek().value == RETURN_OP {
            try expectTokenOfType(.op, withValue: RETURN_OP)
            returnType = try parseType()
        } else {
            returnType = VoidType()
        }
        
        //Parse statement
        var statement = try parseStatement()
        if statement.stType != .returnSt {
            //Ensure that there is an implicit return at the end
            statement = GroupSt([statement, ImplicitReturnSt()])
        }
        
        return MethodDef(isGlobal, isPrivate, methodName, parameterNames, BlockType(TupleType(parameterTypes), returnType), definedInClass, statement)
    }
    
    private func parsePostfixOperator(_ isGlobal: Bool, _ isPrivate: Bool, _ definedInClass: String) throws -> MethodDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.postfixKey.rawValue)
        let op = try expectTokenOfType(.op).value!
        try expectTokenOfType(.op, withValue: RETURN_OP)
        let returnType = try parseType()
        
        //Parse statement
        var statement = try parseStatement()
        if statement.stType != .returnSt {
            //Ensure that there is an implicit return at the end
            statement = GroupSt([statement, ImplicitReturnSt()])
        }
        
        return MethodDef(isGlobal, isPrivate, POST_OP_PREFIX + op, [], BlockType(TupleType([]), returnType), definedInClass, statement)
    }
    
    private func parsePrefixOperator(_ isGlobal: Bool, _ isPrivate: Bool, _ definedInClass: String) throws -> MethodDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.prefixKey.rawValue)
        let op = try expectTokenOfType(.op).value!
        try expectTokenOfType(.op, withValue: RETURN_OP)
        let returnType = try parseType()
        
        //Parse statement
        var statement = try parseStatement()
        if statement.stType != .returnSt {
            //Ensure that there is an implicit return at the end
            statement = GroupSt([statement, ImplicitReturnSt()])
        }
        
        return MethodDef(isGlobal, isPrivate, POST_OP_PREFIX + op, [], BlockType(TupleType([]), returnType), definedInClass, statement)
    }
    
    private func parseProperty(_ isGlobal: Bool, _ isPrivate: Bool, _ definedInClass: String) throws -> PropertyDef {
        try expectTokenOfType(.keyword, withValue: KeywordType.propKey.rawValue)
        let propertyName = try expectTokenOfType(.identifier).value!
        let dataType = try parseType()
        try expectTokenOfType(.op, withValue: ASSIGNMENT_OP)
        return PropertyDef(isGlobal, isPrivate, propertyName, dataType, definedInClass, try parseExpression())
    }
    
    
    //-----Helpers-----
    
    @discardableResult private func expectTokenOfType(_ expectedType: TokenType) throws -> Token {
        let token = lexer.next()
        if token.type == expectedType {
            return token
        }
        throw ParserError.encounteredUnexpectedToken(token: token)
    }
    
    @discardableResult private func expectTokenOfType(_ expectedType: TokenType, withValue: String...) throws -> Token {
        let token = try expectTokenOfType(expectedType)
        for value in withValue {
            if token.value == value {
                return token
            }
        }
        throw ParserError.encounteredUnexpectedToken(token: token)
    }
    
    @discardableResult private func expectTokenOfEitherType(_ expectedTypes: TokenType...) throws -> Token {
        let token = lexer.next()
        if expectedTypes.contains(token.type) {
            return token
        }
        throw ParserError.encounteredUnexpectedToken(token: token)
    }
    
    private func deliminate( _ delimitorType: TokenType, _ delimitorValue: String, _ terminatorType: TokenType, _ terminatorValue: String, _ action: () throws -> (), _ betweenAction: (() throws -> ())?) throws {
        
        if lexer.peek().type != terminatorType || lexer.peek().value != terminatorValue {
            try action()
        } else {
            return
        }
        
        while lexer.peek().type != terminatorType || lexer.peek().value != terminatorValue {
            try expectTokenOfType(delimitorType, withValue: delimitorValue)
            try betweenAction?()
            try action()
        }
    }
    
    
    //-----Parsing Types-----
    
    private func parseType() throws -> Type {
        if lexer.peek().type == .identifier {
            //Parse Class Name
            return ObjectType(try expectTokenOfType(.identifier).value!)
            
        } else if lexer.peek().type == .delimiter && lexer.peek().value == "(" {
            //Parse Block Signature
            var paramTypes = [Type]()
            
            //Parse Parameter Signature
            try expectTokenOfType(.delimiter, withValue: "(")
            try deliminate(.delimiter, ",", .delimiter, ")", {
                paramTypes.append(try parseType())
            }, nil)
            try expectTokenOfType(.delimiter, withValue: ")")
            
            //Parse Return Type
            try expectTokenOfType(.op, withValue: RETURN_OP)
            let returnType = try parseType()
            
            return BlockType(TupleType(paramTypes), returnType)
            
        } else if lexer.peek().type == .op && lexer.peek().value == VOID_SYMBOL {
            try expectTokenOfType(.op, withValue: VOID_SYMBOL)
            return VoidType()
        }
        
        throw ParserError.encounteredUnexpectedToken(token: lexer.peek())
    }
    
}

