//
//  algo.swift
//  golink
//
//  Created by Benzi Ahamed on 13/04/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

func anchors(_ input: String) -> String {
    var a = ""
    let alphanumberics = CharacterSet.alphanumerics
    let whitespace = CharacterSet.whitespaces
    var skipTillSpace = false
    for c in input {
        if !skipTillSpace, let s = c.unicodeScalars.first, alphanumberics.contains(s) {
            a.append(c)
            skipTillSpace = true
        }
        else if skipTillSpace, let s = c.unicodeScalars.first, whitespace.contains(s) {
            skipTillSpace = false
        }
    }
    return a
}

func match(term: String, input: String) -> Int {
    if term.isEmpty || input.isEmpty {
        return Int.min
    }
    if term.count > input.count {
        return Int.min
    }
    var score = 0
    var i = input.startIndex
    var j = term.startIndex
    while j < term.endIndex, i < input.endIndex {
        if input[i] == term[j] {
            score += 1
            j = term.index(after: j)
        } else {
            score -= 1
        }
        i = input.index(after: i)
    }
    if j < term.endIndex {
        return Int.min
    }
    return score
}


func fuzzyMatch(term: String, input: String) -> Int {
    let a = anchors(input)
    let m1 = match(term: term, input: a)
    if m1 == a.count {
        return m1 * 2
    }
    return max(match(term: term, input: input), m1)
}
