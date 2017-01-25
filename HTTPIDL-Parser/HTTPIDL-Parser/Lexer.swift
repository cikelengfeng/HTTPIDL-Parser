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
//    let range: Range<String.CharacterView.Index>
    let string: String
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
        var ok: Bool = true
        var tokens = [RecognizedToken]()
        var workingString = ""
        var workingIndex = source.startIndex
        var workingTrie = dfa
        while workingIndex < source.endIndex {
            let codeUnit = source[workingIndex]
            if let exists = workingTrie.child(key: codeUnit), case .node(let key, _) = exists {
                workingString.append(key)
                workingIndex = source.index(after: workingIndex)
                workingTrie = exists
                
                if workingIndex == source.endIndex {
                    if workingTrie.hasTernimatorChild() {
                        let token = RecognizedToken(string: workingString)
                        tokens.append(token)
                        workingString = ""
                        workingTrie = dfa
                    } else {
                        ok = false
                        break;
                    }
                }
            } else {
                if workingTrie.hasTernimatorChild() {
                    let token = RecognizedToken(string: workingString)
                    tokens.append(token)
                    workingString = ""
                    workingTrie = dfa
                } else {
                    ok = false
                    break;
                }
            }
        }
        return (ok: ok, tokens: tokens)
    }
}



