//
//  Parser.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/26.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

func skipNLAndWS(tokens: [RecognizedToken], from: Array<RecognizedToken>.Index) -> Array<RecognizedToken>.Index {
    var consumedIndex = from
    Loop: while consumedIndex < tokens.endIndex {
        let token = tokens[consumedIndex]
        switch token.type {
        case .fragmentWhitespace, .fragmentNewline:
            consumedIndex = tokens.index(after: consumedIndex)
        default:
            break Loop
        }
    }
    return consumedIndex
}

extension Array {
    func consumeOne(from: Array<Element>.Index, condition: (Element) -> Bool) -> (consumedIndex:Array<Element>.Index, consumedElement: Element)? {
        guard from < self.endIndex else {
            return nil
        }
        let one = self[from]
        if condition(one) {
            return (self.index(after: from), one)
        }
        return nil
    }
}

protocol ParserContext {

    var tokens: [RecognizedToken] {get}
    var text: String {get}
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: Self)
}

enum EntryContextError: HIParserError {
    case missingEOF
}

struct EntryContext: ParserContext {
    let messsages: [MessageContext]
    let structs: [StructContext]
    let EOF: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: EntryContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        var messages: [MessageContext] = []
        var structs: [StructContext] = []
        while consumedIndex < tokens.endIndex {
            let message: MessageContext?
            do {
                let (messageConsumed, messageContext) = try MessageContext.consume(tokens: tokens.subarray(from: consumedIndex))
                message = messageContext
                messages.append(messageContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: messageConsumed)
            } catch let error {
                debugPrint(error)
                message = nil
            }
            guard message == nil else {
                continue
            }
            do {
                let (structConsumed, structContext) = try StructContext.consume(tokens: tokens.subarray(from: consumedIndex))
                structs.append(structContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: structConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        
        guard let (index, eof) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.EOF
        }) else {
            throw EntryContextError.missingEOF
        }
        consumedIndex = index
        return (consumedIndex, EntryContext(messsages: messages, structs: structs, EOF: eof, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum MessageContextError: HIParserError {
    case missingMessageKeyword
    case missingLBrace
    case missingRBrace
}

struct MessageContext: ParserContext {
    let MESSAGE: RecognizedToken
    let uri: URIContext
    let LBRACE: RecognizedToken
    let requests: [RequestContext]
    let responses: [ResponseContext]
    let RBRACE: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: MessageContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume first keyword message
        guard let (indexAfterMsg, messageToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.keywordMessage
        }) else {
            throw MessageContextError.missingMessageKeyword
        }
        consumedIndex = indexAfterMsg
        
        //consume uri
        let (uriConsumed, uri) = try URIContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: uriConsumed)
        
        //consume lbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLBrace, lbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLBrace
        }) else {
            throw MessageContextError.missingLBrace
        }
        consumedIndex = indexAfterLBrace
        
        //consume requests
        var requests: [RequestContext] = []
        var responses: [ResponseContext] = []
        while consumedIndex < tokens.endIndex {
            let request: RequestContext?
            do {
                let (requestConsumed, requestContext) = try RequestContext.consume(tokens: tokens.subarray(from: consumedIndex))
                request = requestContext
                requests.append(requestContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: requestConsumed)
            } catch let error {
                debugPrint(error)
                request = nil
            }
            guard request == nil else {
                continue
            }
            do {
                let (responseConsumed, responseContext) = try ResponseContext.consume(tokens: tokens.subarray(from: consumedIndex))
                responses.append(responseContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: responseConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        
        //consume right brace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRBrace, rbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRBrace
        }) else {
            throw MessageContextError.missingRBrace
        }
        consumedIndex = indexAfterRBrace
        
        //return all above
        return (consumedIndex, MessageContext(MESSAGE: messageToken, uri: uri, LBRACE: lbraceToken, requests: requests, responses: responses, RBRACE: rbraceToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

struct URIContext: ParserContext {
    let components: [URIPathComponentContext]
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: URIContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        var components: [URIPathComponentContext] = []
        while consumedIndex < tokens.endIndex {
            do {
                let (componentConsumed, componentContext) = try URIPathComponentContext.consume(tokens: tokens.subarray(from: consumedIndex))
                components.append(componentContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: componentConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        return (consumedIndex, URIContext(components: components, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum URIPathComponentContextError: HIParserError {
    case missingSlash
}

struct URIPathComponentContext: ParserContext {
    let SLASH: RecognizedToken
    let identifier: IdentifierContext?
    let param: ParamInUriContext?
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: URIPathComponentContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume slash
        guard let (indexAfterSLash, slashToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistSlash
        }) else {
            throw URIPathComponentContextError.missingSlash
        }
        consumedIndex = indexAfterSLash
        
        //consume identifier
        let identifier: IdentifierContext?
        do {
            let (identifierConsumed, identifierContext) = try IdentifierContext.consume(tokens: tokens.subarray(from: consumedIndex))
            consumedIndex = tokens.index(consumedIndex, offsetBy: identifierConsumed)
            identifier = identifierContext
        } catch let error {
            debugPrint(error)
            identifier = nil
        }
        guard identifier == nil else {
            return (consumedIndex, URIPathComponentContext(SLASH: slashToken, identifier: identifier, param: nil, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
        }
        //consume param
        let (paramConsumed, paramContext) = try ParamInUriContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: paramConsumed)
        return (consumedIndex, URIPathComponentContext(SLASH: slashToken, identifier: nil, param: paramContext, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum ParamInUriContextError: HIParserError {
    case missingDollar
}

struct ParamInUriContext: ParserContext {
    let DOLLAR: RecognizedToken
    let identifier: IdentifierContext
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: ParamInUriContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        guard let (indexAfterDollar, dollarToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistDollar
        }) else {
            throw ParamInUriContextError.missingDollar
        }
        consumedIndex = indexAfterDollar
        
        // consume identifier
        let (identifierConsumed, identifierContext) = try IdentifierContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: identifierConsumed)
        
        return (consumedIndex, ParamInUriContext(DOLLAR: dollarToken, identifier: identifierContext, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum IdentifierContextError: HIParserError {
    case missingUnderlineOrChar
}

struct IdentifierContext: ParserContext {
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: IdentifierContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //first token MUST NOT be digit
        guard let (secondIndex, _) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.fragmentChar || token.type == TokenType.assistUnderline
        }) else {
            throw IdentifierContextError.missingUnderlineOrChar
        }
        consumedIndex = secondIndex
        Loop: while consumedIndex < tokens.endIndex {
            let token = tokens[consumedIndex]
            switch token.type {
            case .assistUnderline, .fragmentChar, .fragmentDigit:
                consumedIndex = tokens.index(after: consumedIndex)
            default:
                break Loop
            }
        }
        let range = Range(uncheckedBounds: (contextStart, consumedIndex))
        return (consumedIndex, IdentifierContext(tokens: tokens.subarray(range: range)))
    }
}

enum RequestContextError: HIParserError {
    case missingRequestKeyword
    case missingLBrace
    case missingRBrace
}

struct RequestContext: ParserContext {
    
    let method: MethodContext
    let REQUEST: RecognizedToken
    let LBRACE: RecognizedToken
    let params: [ParamContext]
    let RBRACE: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: RequestContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume method
        let (methodConsumed, methodContext) = try MethodContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: methodConsumed)
        //consume request
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRequest, requestToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.keywordRequest
        }) else {
            throw RequestContextError.missingRequestKeyword
        }
        consumedIndex = indexAfterRequest
        //consume lbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLBrace, lbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLBrace
        }) else {
            throw RequestContextError.missingLBrace
        }
        consumedIndex = indexAfterLBrace
        //consume params
        var params: [ParamContext] = []
        while consumedIndex < tokens.endIndex {
            do {
                let (paramConsumed, paramContext) = try ParamContext.consume(tokens: tokens.subarray(from: consumedIndex))
                params.append(paramContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: paramConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        //consume rbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRBrace, rbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRBrace
        }) else {
            throw RequestContextError.missingRBrace
        }
        consumedIndex = indexAfterRBrace
        
        return (consumedIndex, RequestContext(method: methodContext, REQUEST: requestToken, LBRACE: lbraceToken, params: params, RBRACE: rbraceToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum MethodContextError: HIParserError {
    case missingMethodKeyword
}

struct MethodContext: ParserContext {
    
    let name: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: MethodContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        guard let (indexAfterName, nameToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.methodGet || token.type == TokenType.methodPost || token.type == TokenType.methodPut || token.type == TokenType.methodPatch || token.type == TokenType.methodDelete
        }) else {
            throw MethodContextError.missingMethodKeyword
        }
        consumedIndex = indexAfterName
        return (consumedIndex, MethodContext(name: nameToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum ParamContextError: HIParserError {
    case missingAssign
    case missingSemicolon
}

struct ParamContext: ParserContext {
    
    let type: TypeContext
    let lhs: IdentifierContext
    let ASSIGN: RecognizedToken
    let rhs: IdentifierContext
    let SEMICOLON: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: ParamContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume type
        let (typeConsumed, typeContext) = try TypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: typeConsumed)
        //consume lhs
        let (lhsConsumed, lhsContext) = try IdentifierContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: lhsConsumed)
        //consume assign token
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterAssign, assignToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistAssign
        }) else {
            throw ParamContextError.missingAssign
        }
        consumedIndex = indexAfterAssign
        //consume rhs 
        let (rhsConsumed, rhsContext) = try IdentifierContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: rhsConsumed)
        //consume semicolon
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterSemicolon, semicolonToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistSemicolon
        }) else {
            throw ParamContextError.missingSemicolon
        }
        consumedIndex = indexAfterSemicolon
        
        return (consumedIndex, ParamContext(type: typeContext, lhs: lhsContext, ASSIGN: assignToken, rhs: rhsContext, SEMICOLON: semicolonToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

struct TypeContext: ParserContext {
    
    let nonGenericType: NonGenericTypeContext?
    let genericType: GenericTypeContext?
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: TypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        let nonGenericType: NonGenericTypeContext?
        do {
            let (nonGenericTypeConsumed, nonGenericTypeContext) = try NonGenericTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
            nonGenericType = nonGenericTypeContext
            consumedIndex = tokens.index(consumedIndex, offsetBy: nonGenericTypeConsumed)
        } catch let error {
            debugPrint(error)
            nonGenericType = nil
        }
        guard nonGenericType == nil else {
            return (consumedIndex, TypeContext(nonGenericType: nonGenericType, genericType: nil, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
        }
        let (genericTypeConsumed, genericTypeContext) = try GenericTypeContext.consume(tokens: tokens)
        consumedIndex = tokens.index(consumedIndex, offsetBy: genericTypeConsumed)
        return (consumedIndex, TypeContext(nonGenericType: nil, genericType: genericTypeContext, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

struct NonGenericTypeContext: ParserContext {
    let baseType: BaseTypeContext?
    let customType: IdentifierContext?
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: NonGenericTypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        let baseType: BaseTypeContext?
        do {
            let (baseTypeConsumed, baseTypeContext) = try BaseTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
            baseType = baseTypeContext
            consumedIndex = tokens.index(consumedIndex, offsetBy: baseTypeConsumed)
        } catch let error {
            debugPrint(error)
            baseType = nil
        }
        guard baseType == nil else {
            return (consumedIndex, NonGenericTypeContext(baseType: baseType, customType: nil, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
        }
        let (customTypeConsumed, customTypeContext) = try IdentifierContext.consume(tokens: tokens)
        consumedIndex = tokens.index(consumedIndex, offsetBy: customTypeConsumed)
        return (consumedIndex, NonGenericTypeContext(baseType: nil, customType: customTypeContext, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum BaseTypeContextError: HIParserError {
    case missingTypeKeyword
}

struct BaseTypeContext: ParserContext {
    let name: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: BaseTypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        guard let (indexAfterName, nameToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.typeBlob || token.type == TokenType.typeBool || token.type == TokenType.typeFile || token.type == TokenType.typeInt32 || token.type == TokenType.typeInt64 || token.type == TokenType.typeDouble || token.type == TokenType.typeString
        }) else {
            throw BaseTypeContextError.missingTypeKeyword
        }
        consumedIndex = indexAfterName
        return (consumedIndex, BaseTypeContext(name: nameToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

struct GenericTypeContext: ParserContext {
    let array: ArrayGenericTypeContext?
    let dict: DictGenericTypeContext?
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: GenericTypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        let arrayType: ArrayGenericTypeContext?
        do {
            let (arrayTypeConsumed, arrayTypeContext) = try ArrayGenericTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
            arrayType = arrayTypeContext
            consumedIndex = tokens.index(consumedIndex, offsetBy: arrayTypeConsumed)
        } catch let error {
            debugPrint(error)
            arrayType = nil
        }
        guard arrayType == nil else {
            return (consumedIndex, GenericTypeContext(array: arrayType, dict: nil, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
        }
        let (dictTypeConsumed, dictTypeContext) = try DictGenericTypeContext.consume(tokens: tokens)
        consumedIndex = tokens.index(consumedIndex, offsetBy: dictTypeConsumed)
        return (consumedIndex, GenericTypeContext(array: nil, dict: dictTypeContext, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum ArrayGenericTypeContextError: HIParserError {
    case missingArrayKeyword
    case missingLABracket
    case missingRABracket
}

struct ArrayGenericTypeContext: ParserContext {
    let ARRAY: RecognizedToken
    let LABRACKET: RecognizedToken
    let contentType: NonGenericTypeContext
    let RABRACKET: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: ArrayGenericTypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume array
        guard let (indexAfterArray, arrayToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.typeArray
        }) else {
            throw ArrayGenericTypeContextError.missingArrayKeyword
        }
        consumedIndex = indexAfterArray
        //consume labracket
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLABracket, labracketToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLABracket
        }) else {
            throw ArrayGenericTypeContextError.missingLABracket
        }
        consumedIndex = indexAfterLABracket
        //consume content type
        let (contentTypeConsumed, contentTypeContext) = try NonGenericTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: contentTypeConsumed)
        //consume rabracket
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRABracket, rabracketToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRABracket
        }) else {
            throw ArrayGenericTypeContextError.missingRABracket
        }
        consumedIndex = indexAfterRABracket
        return (consumedIndex, ArrayGenericTypeContext(ARRAY: arrayToken, LABRACKET: labracketToken, contentType: contentTypeContext, RABRACKET: rabracketToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum DictGenericTypeContextError: HIParserError {
    case missingDictKeyword
    case missingLABracket
    case missingRABracket
    case missingComma
}

struct DictGenericTypeContext: ParserContext {
    let DICT: RecognizedToken
    let LABRACKET: RecognizedToken
    let keyType: NonGenericTypeContext
    let COMMA: RecognizedToken
    let valueType: NonGenericTypeContext
    let RABRACKET: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: DictGenericTypeContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume dict
        guard let (indexAfterDict, dictToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.typeDict
        }) else {
            throw DictGenericTypeContextError.missingDictKeyword
        }
        consumedIndex = indexAfterDict
        //consume labracket
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLABracket, labracketToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLABracket
        }) else {
            throw DictGenericTypeContextError.missingLABracket
        }
        consumedIndex = indexAfterLABracket
        //consume key type
        let (keyTypeConsumed, keyTypeContext) = try NonGenericTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: keyTypeConsumed)
        //consume comma
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterComma, commaToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistComma
        }) else {
            throw DictGenericTypeContextError.missingComma
        }
        consumedIndex = indexAfterComma
        //consume value type
        let (valueTypeConsumed, valueTypeContext) = try NonGenericTypeContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: valueTypeConsumed)
        //consume rabracket
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRABracket, rabracketToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRABracket
        }) else {
            throw DictGenericTypeContextError.missingRABracket
        }
        consumedIndex = indexAfterRABracket
        
        return (consumedIndex, DictGenericTypeContext(DICT: dictToken, LABRACKET: labracketToken, keyType: keyTypeContext, COMMA: commaToken, valueType: valueTypeContext, RABRACKET: rabracketToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum ResponseContextError: HIParserError {
    case missingResponseKeyword
    case missingLBrace
    case missingRBrace
}

struct ResponseContext: ParserContext {
    let method: MethodContext
    let RESPONSE: RecognizedToken
    let LBRACE: RecognizedToken
    let params: [ParamContext]
    let RBRACE: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: ResponseContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume method
        let (methodConsumed, methodContext) = try MethodContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: methodConsumed)
        //consume response
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard consumedIndex < tokens.endIndex, tokens[consumedIndex].type == TokenType.keywordRespsonse else {
            throw ResponseContextError.missingResponseKeyword
        }
        let responseToken = tokens[consumedIndex]
        consumedIndex = tokens.index(after: consumedIndex)
        //consume lbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLBrace, lbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLBrace
        })else {
            throw ResponseContextError.missingLBrace
        }
        consumedIndex = indexAfterLBrace
        //consume params
        var params: [ParamContext] = []
        while consumedIndex < tokens.endIndex {
            do {
                let (paramConsumed, paramContext) = try ParamContext.consume(tokens: tokens.subarray(from: consumedIndex))
                params.append(paramContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: paramConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        //consume rbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRBrace, rbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRBrace
        }) else {
            throw RequestContextError.missingRBrace
        }
        consumedIndex = indexAfterRBrace
        
        return (consumedIndex, ResponseContext(method: methodContext, RESPONSE: responseToken, LBRACE: lbraceToken, params: params, RBRACE: rbraceToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

enum StructContextError: HIParserError {
    case missingStructKeyword
    case missingLBrace
    case missingRBrace
}

struct StructContext: ParserContext {
    
    let STRUCT: RecognizedToken
    let name: IdentifierContext
    let LBRACE: RecognizedToken
    let params: [ParamContext]
    let RBRACE: RecognizedToken
    
    let tokens: [RecognizedToken]
    var text: String {
        get {
            return tokens.reduce("") { (soFar, soGood) in
                return soFar + soGood.string
            }
        }
    }
    
    static func consume(tokens: [RecognizedToken]) throws -> (consumedIndex: Array<RecognizedToken>.Index, context: StructContext) {
        let contextStart = skipNLAndWS(tokens: tokens, from: tokens.startIndex)
        var consumedIndex = contextStart
        //consume struct
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterStruct, structToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.keywordStruct
        }) else {
            throw StructContextError.missingStructKeyword
        }
        consumedIndex = indexAfterStruct
        //consume name
        let (nameConsumed, nameContext) = try IdentifierContext.consume(tokens: tokens.subarray(from: consumedIndex))
        consumedIndex = tokens.index(consumedIndex, offsetBy: nameConsumed)
        //consume lbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterLBrace, lbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistLBrace
        }) else {
            throw StructContextError.missingLBrace
        }
        consumedIndex = indexAfterLBrace
        //consume params
        var params: [ParamContext] = []
        while consumedIndex < tokens.endIndex {
            do {
                let (paramConsumed, paramContext) = try ParamContext.consume(tokens: tokens.subarray(from: consumedIndex))
                params.append(paramContext)
                consumedIndex = tokens.index(consumedIndex, offsetBy: paramConsumed)
            } catch let error {
                debugPrint(error)
                break
            }
        }
        //consume rbrace
        consumedIndex = skipNLAndWS(tokens: tokens, from: consumedIndex)
        guard let (indexAfterRBrace, rbraceToken) = tokens.consumeOne(from: consumedIndex, condition: { (token) -> Bool in
            return token.type == TokenType.assistRBrace
        }) else {
            throw StructContextError.missingRBrace
        }
        consumedIndex = indexAfterRBrace
        
        return (consumedIndex, StructContext(STRUCT: structToken, name: nameContext, LBRACE: lbraceToken, params: params, RBRACE: rbraceToken, tokens: tokens.subarray(range: Range(uncheckedBounds: (contextStart, consumedIndex)))))
    }
}

struct Parser {
    
    func parse(tokens: [RecognizedToken]) throws -> EntryContext {
        let (_, entry) = try EntryContext.consume(tokens: tokens)
        return entry
    }
}
