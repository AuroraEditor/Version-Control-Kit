//
//  IRemote.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

private var forkedRemotePrefix = "aurora-editor-"

public func forkPullRequestRemoteName(remoteName: String) -> String {
    return "\(forkedRemotePrefix)\(remoteName)"
}

public protocol IRemote {
    var name: String { get }
    var url: String { get }
}

public struct GitRemote: IRemote, Hashable {
    public var id: String { self.name }
    public var name: String
    public var url: String

    init(name: String, url: String) {
        self.name = name
        self.url = url
    }

    public static func == (lhs: GitRemote, rhs: GitRemote) -> Bool {
        return lhs.name == rhs.name
    }
}
