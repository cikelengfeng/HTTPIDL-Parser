//
//  ParserRule.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/27.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

enum ParserRuleType {
    case entry // : (messageDecl | structDecl)* EOF
    case messageDecl //: MESSAGE uriDecl LBrace (requestDecl | responseDecl)* RBrace
    case structDecl //: STRUCT identifierDecl LBrace bindDecl* RBrace
    case uriDecl //: uriPathComponent*
    case uriPathComponent //: SLASH (identifierDecl | paramInUriDecl)
    case requestDecl//: methodDecl REQUEST LBrace bindDecl* RBrace
    case responseDecl//: methodDecl RESPONSE LBrace bindDecl* RBrace
    case methodDecl//: GET | POST | PUT | DELETE | PATCH
    case bindDecl//: typeDecl identifier ASSIGN identifier SEMICOLON
    case paramInUriDecl//: DOLLAR identifier
    case typeDecl//: nonGenericTypeDecl | genericTypeDecl
    case genericTypeDecl//: arrayGenericTypeDecl | dictGenericTypeDecl
    case arrayGenericTypeDecl//: ARRAY LABracket nonGenericTypeDecl RABracket
    case dictGenericTypeDecl//: ARRAY LABracket nonGenericTypeDecl COMMA nonGenericTypeDecl RABracket
    case nonGenericTypeDecl//: baseTypeDecl | identifierDecl
    case baseTypeDecl//: INT64 | INT32 | BOOL | DOUBLE | STRING | FILE | BLOB
    case identifierDecl//: (UNDERLINE | CHAR) (UNDERLINE | CHAR | DIGIT)*
    case exit
}


