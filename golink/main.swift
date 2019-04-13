//
//  main.swift
//  golink
//
//  Created by Benzi Ahamed on 11/04/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

Alfred.preparePaths()

let go = GoLinks(storage: FileLinkStorage(path: "links.txt"))

// --query <query>
// --go <id>
// --add <name> <url>
// --delete <id>
// --rm
// --db <file>

var i = 1 // skip name of program
var current: String? {
    return i < CommandLine.arguments.count ? CommandLine.arguments[i] : nil
}
func advance() {
    i += 1
}

enum Mode {
    case process(query: String)
    case add(name: String, path: String)
    case go(id: String)
    case delete(id: String)
    case clear
    case nothing
}

var db = "links.txt"
var mode = Mode.process(query: "")

func parse(fragments: [String]) -> (name: String, path: String)? {
    guard fragments.count >= 2 else {
        return nil
    }
    var url = fragments.last!
    guard url.hasPrefix("http") || url.hasPrefix("www") else {
        return nil
    }
    let name = fragments.dropLast().joined(separator: " ")
    if url.hasPrefix("www.") {
        url = "http://\(url)"
    }
    return (name, url)
}

while let arg = current {
    switch arg {

    case "--db":
        advance()
        guard let f = current else {
            Alfred.quit("expected db after --db")
        }
        db = f
        advance()

    case "rm":
        advance()
        mode = .clear
        
    case "query":
        advance()
        var queryFragments: [String] = []
        while let q = current {
            advance()
            queryFragments.append(q)
        }
        mode = .process(query: queryFragments.joined(separator: " "))
        break
        
    case "add":
        advance()
        var inputs: [String] = []
        while let c = current {
            inputs.append(c)
            advance()
        }
        guard let link = parse(fragments: inputs) else {
            Alfred.quit("expected a name and URL after add")
        }
        mode = .add(name: link.name, path: link.path)
        
    case "go":
        advance()
        guard let id = current else {
            Alfred.quit("expected id after go")
        }
        mode = .go(id: id)
        
    case "rmgo":
        advance()
        guard let id = current else {
            Alfred.quit("expected id after go")
        }
        mode = .delete(id: id)
        
    default:
        advance()
        break
    }
}

let dbPath = Alfred.data(path: db)


switch mode {

case .clear:
    try? FileManager.default.removeItem(atPath: dbPath)
    
case let .process(query):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    let links = go.query(term: query).map { link in AlfredResultItem.with { $0.title = link.name; $0.subtitle = link.path; $0.arg = "go \(link.id)" } }
    let alfred = Alfred()
    if links.isEmpty {
        if let link = parse(fragments: query.split(separator: " ").map { "\($0)" }) {
            alfred.add(.with { $0.title = "+ \(link.name)"; $0.subtitle = link.path; $0.arg = "add \(query)" })
        } else {
            alfred.add(.with { $0.title = "No links found!"; $0.valid = false })
        }
    } else {
        links.forEach { alfred.add($0) }
    }
    print(alfred.json)
    
    
case let .add(name, path):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    go.add(name: name, path: path)
    
    
case let .go(id):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    if let link = go.get(id: id) {
        let p = Process()
        p.executableURL = URL.init(fileURLWithPath: "/usr/bin/open")
        p.arguments = [link.path]
        try? p.run()
    }
    
case let .delete(id):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    go.delete(id: id)

default:
    break

}
