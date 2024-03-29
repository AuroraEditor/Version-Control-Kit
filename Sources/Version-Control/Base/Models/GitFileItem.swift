//
//  GitFileItem.swift
//
//
//  Created by Nanashi Li on 2022/10/05.
//

import Foundation

@available(macOS, deprecated, message: "Use `FileChange` instead")
public protocol GitFileItem: Codable {

    var gitStatus: GitType? { get set }

    /// Returns the URL of the ``FileSystemClient/FileSystemClient/FileItem``
    var url: URL { get set }
}
