//
//  Lexer.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/25.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

let terminatorUUID = UUID().uuidString

enum Trie {
    indirect case node(Character, [Trie])
    case terminator
}

extension Trie: Equatable {
    public static func ==(lhs: Trie, rhs: Trie) -> Bool {
        switch (lhs, rhs) {
        case (.node(let lKey, _), .node(let rKey, _)):
            return lKey == rKey
        case (.terminator, .terminator):
            return true
        default: return false
        }
    }
}

extension Trie: Hashable {
    var hashValue: Int {
        switch self {
        case .node(let key, _):
            return key.hashValue
        case .terminator:
            return terminatorUUID.hashValue
        }
    }
}

extension Trie {
    //将一个单词(输入的字符串)插入到前缀树中
    mutating func insert(string: String) {
        guard !string.isEmpty else {
            self.insert(child: Trie.terminator)
            return
        }
        
        let codeUnit = string.characters[string.startIndex]
        var next: Trie
        if let exists = self.child(key: codeUnit) {
            next = exists
        } else {
            next = Trie.node(codeUnit, [])
        }
        next.insert(string: string.substring(from: string.index(after: string.startIndex)))
        self.insert(child: next)
    }
    
    func hasTernimatorChild() -> Bool {
        return contains(child: Trie.terminator)
    }
    
    func contains(child: Trie) -> Bool {
        guard case .node(_, let children) = self else {
            return false
        }
        return children.contains(where: { (trie) -> Bool in
            return trie == child
        })
    }
    
    func child(key: Character) -> Trie? {
        guard case .node(_, let children) = self else {
            return nil
        }
        return children.first(where: { (trie) -> Bool in
            guard case .node(let childKey, _) = trie else {
                return false
            }
            return key == childKey
        })
    }
    
    //插入一个child，如果插入的child的key已存在，则将child与已存在的child合并
    mutating func insert(child: Trie) {
        guard case .node(let key, let children) = self else {
            return
        }
        let needAppend: Trie
        if case .node(let childKey, _) = child, let exists = self.child(key: childKey) {
            needAppend = Trie.merge(lhs: exists, rhs: child)!
        } else {
            needAppend = child
        }
        var tmp = Set(children)
        if tmp.contains(needAppend) {
            tmp.remove(needAppend)
        }
        tmp.insert(needAppend)
        self = .node(key, Array(tmp))
    }
    
    //递归合并两个trie，只有相同的key的node或两个terminator可以合并，其他情况会返回nil
    static func merge(lhs: Trie, rhs: Trie) -> Trie? {
        switch (lhs, rhs) {
        case (.node(let lKey, let lChildren), .node(let rKey, let rChildren)):
            guard lKey == rKey else {
                return nil
            }
            let ls = Set(lChildren)
            let rs = Set(rChildren)
            let intersection = ls.intersection(rs)
            var tmp = ls.symmetricDifference(rs)
            intersection.forEach({ (trie) in
                let linter = lChildren[lChildren.index(of: trie)!]
                let rinter = rChildren[rChildren.index(of: trie)!]
                if let merged = Trie.merge(lhs: linter, rhs: rinter) {
                    tmp.insert(merged)
                }
            })
            return .node(lKey, Array(tmp))
        case (.terminator, .terminator):
            return .terminator
        default: return nil
        }
    }
}

struct RecognizedToken {
    let range: Range<String.CharacterView.Index>
    let string: String
}

extension RecognizedToken: CustomDebugStringConvertible {
    var debugDescription: String {
        get {
            return "<\"\(string)\">"
        }
    }
}

struct Lexer {
    let dfa: Trie
    
    init(tokens: [String]) {
        var root = Trie.node("x", [])
        tokens.forEach { (token) in
            root.insert(string: token)
        }
        dfa = root
    }
    
    func recognize(source: String) -> (ok: Bool, tokens: [RecognizedToken]) {
        //是否完全识别了输入的语言
        var ok: Bool = true
        //识别到的token数组
        var tokens = [RecognizedToken]()
        //当前正在识别的字符的位置
        var workingIndex = source.startIndex
        //识别到的可能是token的字符串的位置（已经跳转到了某个状态）
        var workingStringLocation: String.Index? = nil
        //最后一个识别到的终结符的位置
        var lastTerminatorParentIndex: String.Index? = nil
        //在识别的过程中我们会不断深入到一颗前缀树的子树中，这个临时变量就是用来记录当前用于识别的前缀树
        var workingTrie = dfa
        //遍历所有的输入字符
        while workingIndex < source.endIndex {
            //取出当前用于识别的字符
            let codeUnit = source[workingIndex]
            //无论如何，如果当前前缀树有终结符，我们都先记录下来
            if workingTrie.hasTernimatorChild() {
                lastTerminatorParentIndex = workingIndex
            }
            if let exists = workingTrie.child(key: codeUnit) {
                //如果没有记录过workingStringLocation，则说明当前字符是某个token的第一个字符
                if workingStringLocation == nil {
                    workingStringLocation = workingIndex
                }
                //将工作位置往后移一位，并将匹配到的子树赋值给工作前缀树，用于识别下一个字符
                workingIndex = source.index(after: workingIndex)
                workingTrie = exists
                //已经到了文件末尾，要特殊处理一下，如果当前已经跳转到到了某个状态并且前缀树有终结符，那么我们就成功的识别到了最后一个token，反之，说明最后一个token并没有写完整，则识别失败。
                if workingIndex == source.endIndex {
                    if workingTrie.hasTernimatorChild(), let tokenFrom = workingStringLocation {
                        let tokenRange = Range(uncheckedBounds: (lower: tokenFrom, upper: workingIndex))
                        let tokenString = source.substring(with: tokenRange)
                        let token = RecognizedToken(range: tokenRange, string: tokenString)
                        tokens.append(token)
                    } else {
                        ok = false
                        break
                    }
                }
            } else if let tokenTo = lastTerminatorParentIndex, let tokenFrom = workingStringLocation {
                //如果当前字符没有被当前前缀树识别，输出当前识别到的最长token，并将工作位置回退到该token的末尾，然后继续识别
                let tokenRange = Range(uncheckedBounds: (lower: tokenFrom, upper: tokenTo))
                let tokenString = source.substring(with: tokenRange)
                let token = RecognizedToken(range: tokenRange, string: tokenString)
                tokens.append(token)
                //已经识别到一个token，清理现场
                workingIndex = tokenTo
                workingStringLocation = nil
                workingTrie = dfa
                lastTerminatorParentIndex = nil
            } else {
                ok = false
                break
            }
            
        }
        //所有字符消耗完毕，输出是否成功识别此语言，以及识别到的所有token
        return (ok: ok, tokens: tokens)
    }
}



