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
            .filter { $0.1 > Int.min }
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
