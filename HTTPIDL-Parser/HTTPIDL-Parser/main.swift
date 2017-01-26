//
//  main.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/25.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

print("Hello, World!")

let lexicalRules = ["MESSAGE","STRUCT","REQUEST","RESPONSE","GET","POST","PUT","DELETE","PATCH","INT64","INT32","BOOL","DOUBLE","STRING","FILE","BLOB","ARRAY","DICT","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9","=",";"," ","\n","\t","\r","{","}","<",">","=","$","/",","]
//let lexicalRules = ["m","mee","ed"]
let lexer = Lexer(lexicalRules: lexicalRules)

//print(lexer.dfa)

let file = URL(fileURLWithPath: "/Users/xudong/Desktop/HTTPIDLParserExample/Example")
let source = try! String(contentsOf: file)
//let source = "med"
let recognization = lexer.recognize(source: source)

print(recognization)
