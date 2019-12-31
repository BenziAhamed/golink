//
//  main.swift
//  golink
//
//  Created by Benzi Ahamed on 11/04/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

enum Mode {
    case process(query: String)
    case add(name: String, path: String)
    case go(id: String)
    case delete(id: String)
    case clear
    case nothing
}

Alfred.preparePaths()
var db = "links.txt"
var mode = Mode.process(query: "")


func _parseAddOptions(query: [String]) -> Mode {
    guard let link = parse(text: query.joined(separator: " ")), case .link = link.match else {
        Alfred.quit("expected a name and URL after add")
    }
    return .add(name: link.name, path: link.path)
}

var args = Args()

args.flag("rm")         { mode = .clear }
args.option("--db",     { db = $0})                         { Alfred.quit("expected db after --db") }
args.option("go",       { mode = .go(id: $0) })             { Alfred.quit("expected id after go") }
args.option("rmgo",     { mode = .delete(id: $0) })         { Alfred.quit("expected id after rmgo") }
args.consume("query")   { mode = .process(query: $0.joined(separator: " ")) }
args.consume("add")     { mode = _parseAddOptions(query: $0) }

args.process()

let dbPath = Alfred.data(path: db)

switch mode {

case .clear:
    try? FileManager.default.removeItem(atPath: dbPath)
    
case let .process(query):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    let links = go.query(term: query).map { link in AlfredResultItem.with {
        $0.title = link.name
        $0.subtitle = link.path
        $0.arg = "go \(link.id)"
        $0.autocomplete = "\(link.name) \(link.path)"
        }
    }
    let alfred = Alfred()
    if !links.isEmpty {
        links.forEach { alfred.add($0) }
        alfred.done()
    }
    
    if let link = parse(text: query) {
        if case .scheme = link.match {
            alfred.add(.with { $0.title = "+ \(link.name)"; $0.subtitle = "Enter link: \(link.path)<?>"; $0.valid = false; })
        } else {
            alfred.add(.with { $0.title = "+ \(link.name)"; $0.subtitle = link.path; $0.arg = "add \(query)" })
        }
    } else {
        alfred.add(.with { $0.title = "No links found!"; $0.valid = false })
    }

    alfred.done()
    
    
case let .add(name, path):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    go.add(name: name, path: path)
    
    
case let .go(id):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    if let link = go.get(id: id) {
        print(link.path)
    }
    
case let .delete(id):
    let go = GoLinks.init(storage: FileLinkStorage(path: dbPath))
    go.delete(id: id)

default:
    break

}
