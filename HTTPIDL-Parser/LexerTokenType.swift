//
//  LexerTokens.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/27.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

enum TokenType {
    case keywordMessage
    case keywordStruct
    case keywordRequest
    case keywordRespsonse
    case methodGet
    case methodPost
    case methodPut
    case methodDelete
    case methodPatch
    case typeInt64
    case typeInt32
    case typeBool
    case typeDouble
    case typeString
    case typeFile
    case typeBlob
    case typeArray
    case typeDict
    case assistLBrace
    case assistRBrace
    case assistLABracket
    case assistRABracket
    case assistAssign
    case assistDollar
    case assistComma
    case assistSemicolon
    case assistSlash
    case assistUnderline
    case fragmentChar
    case fragmentDigit
    case fragmentNewline
    case fragmentWhitespace
    case EOF
}

