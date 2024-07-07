//
//  GitAuthor.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitAuthor: Codable, Hashable, Equatable {
    public var name: String
    public var email: String

    public init(name: String?, email: String?) {
        self.name = name ?? "Unknown"
        self.email = email ?? "Unknown"
    }

    public func parse(nameAddr: String) -> GitAuthor? {
        let value = nameAddr.components(separatedBy: "/^(.*?)\\s+<(.*?)>//")
        return value.isEmpty ? nil : GitAuthor(name: value[1],
                                              email: value[2])
    }

    public func toString() -> String {
        return "\(self.name) \(self.email)"
    }

    public static func == (lhs: GitAuthor, rhs: GitAuthor) -> Bool {
        lhs.email == rhs.email
    }
}
