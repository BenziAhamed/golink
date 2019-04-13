//
//  Core.swift
//  golink
//
//  Created by Benzi Ahamed on 11/04/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

struct Link : Codable {
    let id: String
    let name: String
    let path: String
}

protocol LinkStorage {
    func getLinks() -> [Link]
    func add(link: Link)
    func delete(id: String)
    func get(id: String) -> Link?
}

class InMemoryLinkStorage : LinkStorage {
    
    var links = [Link]()
    
    func getLinks() -> [Link] {
        return links
    }
    
    func add(link: Link) {
        links.append(link)
    }
    
    func delete(id: String) {
        links = links.filter { $0.id != id }
    }
    
    func get(id: String) -> Link? {
        return links.first(where: { $0.id == id })
    }
}


class FileLinkStorage : LinkStorage {
    
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    func getLinks() -> [Link] {
        guard let data = FileManager.default.contents(atPath: path) else {
            return []
        }
        let decoder = JSONDecoder()
        let links = try? decoder.decode([Link].self, from: data)
        return links ?? []
    }
    
    func add(link: Link) {
        var links = getLinks()
        links.append(link)
        save(links)
    }
    
    func delete(id: String) {
        let links = getLinks().filter { $0.id != id }
        save(links)
    }
    
    private func save(_ links: [Link]) {
        guard let data = try? JSONEncoder().encode(links) else {
            return
        }
        try? data.write(to: URL.init(fileURLWithPath: path), options: .atomicWrite)
    }
    
    func get(id: String) -> Link? {
        return getLinks().first(where: { $0.id == id })
    }
    
}


class GoLinks {
    let storage: LinkStorage
    
    init(storage: LinkStorage) {
        self.storage = storage
    }
}

extension GoLinks {
    func query(term: String) -> [Link] {
        let links = storage.getLinks()
        if term.isEmpty {
            return links
        }
        return links
            .map {
                return ($0, fuzzyMatch(term: term, input: $0.name))
            }
            .filter { $0.1 > -25 }
            .sorted(by: { $0.1 > $1.1 })
            .map { $0.0 }
    }
    
    func delete(id: String) {
        storage.delete(id: id)
    }
    
    func add(name: String, path: String) {
        storage.add(link: Link.init(id: UUID().uuidString, name: name, path: path))
    }
    
    func get(id: String) -> Link? {
        return storage.get(id: id)
    }
    
    func run(id: String) {
        guard let link = storage.get(id: id) else {
            return
        }
        print(link.path)
    }
}

struct AlfredResultItem : Codable {
    var title = ""
    var subtitle: String? = nil
    var arg: String? = nil
    var valid: Bool? = nil
    
    init() { }
    
    static func with(_ populator: (inout AlfredResultItem) -> Void) -> AlfredResultItem {
        var item = AlfredResultItem()
        populator(&item)
        return item
    }
}

struct AlfredResultList : Codable {
    var items = [AlfredResultItem]()
    
    var json: String {
        guard let data = try? JSONEncoder().encode(self),
            let json = String.init(data: data, encoding: .utf8) else {
                return """
                {
                "items": []
                }
                """
        }
        return json
    }
}


class Alfred {
    
    static func preparePaths() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: data(), withIntermediateDirectories: false, attributes: nil)
        try? fm.createDirectory(atPath: cache(), withIntermediateDirectories: false, attributes: nil)
    }
    
    static func data(path: String? = nil) -> String {
        return folder(type: "data", path: path)
    }
    
    static func cache(path: String? = nil) -> String {
        return folder(type: "cache", path: path)
    }
    
    static func folder(type: String, path: String? = nil) -> String {
        let base = ProcessInfo().environment["alfred_workflow_\(type)"] ?? "."
        guard let path = path else { return base }
        return "\(base)/\(path)"
    }
    
    static func env(_ name: String) -> String? {
        return ProcessInfo().environment[name]
    }
    
    private var results = AlfredResultList()
    
    func add(_ item: AlfredResultItem) {
        results.items.append(item)
    }
    
    var json: String {
        return results.json
    }
    
    static func quit(_ title: String, _ subtitle: String? = nil) -> Never {
        let a = Alfred()
        a.add(.with { $0.title = title; $0.subtitle = subtitle ?? "" })
        print(a.json)
        exit(0)
    }
    
}
