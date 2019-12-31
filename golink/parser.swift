//
//  parser.swift
//  golink
//
//  Created by Benzi Ahamed on 30/12/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

enum LinkPatternMatch {
    case link(String)
    case scheme
    case none
}

func matchLink(_ text: String) -> LinkPatternMatch {
    let allowedPrefixes = ["http://","https://","www.","file://"]
    guard allowedPrefixes.contains(where: { text.hasPrefix($0) }) else {
        return .none
    }
    return allowedPrefixes.contains(text) ?
        .scheme
        :
        .link(text.hasPrefix("www.") ?
            "http://\(text)"
            :
            text
        )
}

struct ParseOutput {
    let name: String
    let path: String
    let match: LinkPatternMatch
}

// input must be `text url` format
func parse(text: String) -> ParseOutput? {
    let fragments = text.split(separator: " ")
    guard fragments.count >= 2 else {
        return nil
    }
    
    let url = fragments.last!
    let name = fragments.dropLast().joined(separator: " ")
    
    let match = matchLink(String(url))
    switch match {
    case .none:
        return nil
    case .scheme:
        return .init(name: String(name), path: String(url), match: match)
    case let .link(link):
        return .init(name: String(name), path: link, match: match)
    }
}
