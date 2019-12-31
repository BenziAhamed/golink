//
//  alfred.swift
//  golink
//
//  Created by Benzi Ahamed on 30/12/19.
//  Copyright © 2019 Benzi. All rights reserved.
//

import Foundation

struct AlfredResultItem : Codable {
    var title = ""
    var subtitle: String? = nil
    var arg: String? = nil
    var valid: Bool? = nil
    var autocomplete: String? = nil
    
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
    
    func done() {
        print(json)
        exit(0)
    }
    
}
