//
//  Array+Helper.swift
//  HTTPIDL-Parser
//
//  Created by 徐 东 on 2017/1/27.
//  Copyright © 2017年 dx lab. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    mutating func remove(elements: [Element]) -> [Element] {
        var ret: [Element] = []
        elements.forEach { (element) in
            guard let index = self.index(of: element) else {
                return
            }
            let removed = self.remove(at: index)
            ret.append(removed)
        }
        return ret
    }
    
    mutating func remove(element: Element) -> Element? {
        guard let index = self.index(of: element) else {
            return nil
        }
        return self.remove(at: index)
    }
}

extension Array {
    func subarray(from: Index) -> [Element] {
        return Array(self[from ..< self.endIndex])
    }
    
    func subarray(to: Index) -> [Element] {
        return Array(self[self.startIndex ..< to])
    }
    
    func subarray(range: Range<Index>) -> [Element] {
        return Array(self[range])
    }
}

