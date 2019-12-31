//
//  args.swift
//  golink
//
//  Created by Benzi Ahamed on 30/12/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

struct Args {
    
    private var i = 1 // skip name of program
    private let args: [String]
    
    init(args: [String]) {
        self.args = args
    }
    
    init() {
        self.args = CommandLine.arguments
    }
    
    var current: String? {
        return i < args.count ? args[i] : nil
    }

    mutating func advance() {
        i += 1
    }
    
    var options = [ArgOption]()
    var flags = [ArgFlag]()
    var consumers = [ArgConsumer]()
}

struct ArgFlag {
    let name: String
    let callback: () -> Void
}

struct ArgOption {
    let name: String
    let callback: (String) -> Void
    let onError: () -> Void
}

struct ArgConsumer {
    let name: String
    let callback: ([String]) -> Void
}

extension Args {
    
    mutating func flag(_ name: String, callback: @escaping () -> Void) {
        flags.append(.init(name: name, callback: callback))
    }
    
    mutating func option(_ name: String, _ run: @escaping (String) -> Void, error: @escaping () -> Void) {
        options.append(.init(name: name, callback: run, onError: error))
    }
    
    mutating func consume(_ name: String, run: @escaping ([String]) -> Void) {
        consumers.append(.init(name: name, callback: run))
    }
    
    mutating func process() {
        while let arg = current {
            
            // consumer?
            if let consumer = consumers.first(where: { $0.name == arg }) {
                advance()
                var params = [String]()
                while let arg = current {
                    advance()
                    params.append(arg)
                }
                consumer.callback(params)
                continue
            }
            
            // flag?
            if let flag = flags.first(where: { $0.name == arg }) {
                advance()
                flag.callback()
                continue
            }
            
            // option something?
            if let option = options.first(where: { $0.name == arg }) {
                advance()
                guard let value = current else {
                    option.onError()
                    continue
                }
                advance()
                option.callback(value)
                continue
            }
            
            // else just skip
            advance()
        }
    }
}
