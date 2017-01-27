//
//  Parser.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/26.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

struct EntryContext {
    var messsages: [MessageContext]
    var structs: [StructContext]
}

struct MessageContext {
    var MESSAGE: String
    var uri: URIContext
    var L_BRACE: String
    var requests: [RequestContext]
    var responses: [ResponseContext]
    var R_BRACE: String
}

struct URIContext {
    
}

struct RequestContext {
    
}

struct ResponseContext {
    
}

struct StructContext {
    
}

struct Parser {
    
}
