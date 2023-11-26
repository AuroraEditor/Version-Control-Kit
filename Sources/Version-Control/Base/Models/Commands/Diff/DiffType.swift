//
//  DiffType.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public enum DiffType {
    /// Changes to a text file, which may be partially selected for commit
    case text
    /// Changes to a file with a known extension, which can be viewed in the editor
    case image
    /// Changes to an unknown file format, which Git is unable to present in a human-friendly format
    case binary
    /// Change to a repository which is included as a submodule of this repository
    case submodule
    /// Diff is large enough to degrade ux if rendered
    case largeText
    /// Diff that will not be rendered
    case unrenderable
}
