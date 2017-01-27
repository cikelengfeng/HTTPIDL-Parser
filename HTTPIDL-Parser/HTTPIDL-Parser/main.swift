//
//  main.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/25.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

print("Hello, World!")

let lexicalRules: [(String, TokenType)] = [
    ("MESSAGE", .keywordMessage),("STRUCT", .keywordStruct),("REQUEST", .keywordRequest),("RESPONSE", .keywordRespsonse),("GET", .methodGet),("POST", .methodPost),("PUT", .methodPut), ("DELETE", .methodDelete),("INT64", .typeInt64),("INT32", .typeInt32),("BOOL", .typeBool),("DOUBLE", .typeDouble),("STRING", .typeString),("FILE", .typeFile),("BLOB", .typeBlob),("ARRAY", .typeArray),("DICT", .typeDict),
("a", .fragmentChar),("b", .fragmentChar),("c", .fragmentChar),("d", .fragmentChar),("e", .fragmentChar),("f", .fragmentChar),("g", .fragmentChar),("h", .fragmentChar),("i", .fragmentChar),("j", .fragmentChar),("k", .fragmentChar),("l", .fragmentChar),("m", .fragmentChar),("n", .fragmentChar),("o", .fragmentChar),("p", .fragmentChar),("q", .fragmentChar),("r", .fragmentChar),("s", .fragmentChar),("t", .fragmentChar),("u", .fragmentChar),("v", .fragmentChar),("w", .fragmentChar),("x", .fragmentChar),("y", .fragmentChar),("z", .fragmentChar),("A", .fragmentChar),("B", .fragmentChar),("C", .fragmentChar),("D", .fragmentChar),("E", .fragmentChar),("F", .fragmentChar),("G", .fragmentChar),("H", .fragmentChar),("I", .fragmentChar),("J", .fragmentChar),("K", .fragmentChar),("L", .fragmentChar),("M", .fragmentChar),("N", .fragmentChar),("O", .fragmentChar),("P", .fragmentChar),("Q", .fragmentChar),("R", .fragmentChar),("S", .fragmentChar),("T", .fragmentChar),("U", .fragmentChar),("V", .fragmentChar),("W", .fragmentChar),("X", .fragmentChar),("Y", .fragmentChar),("Z", .fragmentChar),
                    ("0", .fragmentDigit),("1", .fragmentDigit),("2", .fragmentDigit),("3", .fragmentDigit),("4", .fragmentDigit),("5", .fragmentDigit),("6", .fragmentDigit),("7", .fragmentDigit),("8", .fragmentDigit),("9", .fragmentDigit),
                    ("=", .assistAssign),(";", .assistSemicolon),("{", .assistLBrace),("}", .assistRBrace),("<", .assistLABracket),(">", .assistRABracket),("$", .assistDollar),("/", .assistSlash),(",", .assistComma),("_", .assistUnderline),
                    (" ", .fragmentWhitespace),("\t", .fragmentWhitespace),("\n", .fragmentNewline),("\r", .fragmentNewline)]

let lexer = Lexer(lexicalRules: lexicalRules)
let file = URL(fileURLWithPath: "/Users/xudong/Desktop/HTTPIDLParserExample/Example")
let source = try! String(contentsOf: file)
let (ok, tokens) = lexer.recognize(source: source)

print("lexer result: ", ok)
//print(tokens)

let parser = Parser()
let ast = try parser.parse(tokens: tokens)

print(ast)
