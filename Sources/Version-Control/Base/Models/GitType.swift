//
//  GitType.swift
//  
//
//  Created by Nanashi Li on 2022/05/20.
//

import Foundation

// Used to determine the git type
@available(macOS, deprecated, message: "We use the new AppFileStatus protocol")
public enum GitType: String, Codable {
    case modified = "M"
    case unknown = "??"
    case fileTypeChange = "T"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case updatedUnmerged = "U"
    case ignored = "!"
    case unchanged = "."

    public var description: String {
        switch self {
        case .modified: return "M"
        case .unknown: return "?"
        case .fileTypeChange: return "T"
        case .added: return "A"
        case .deleted: return "D"
        case .renamed: return "R"
        case .copied: return "C"
        case .updatedUnmerged: return "U"
        case .ignored: return "!"
        case .unchanged: return "."
        }
    }
}

/// The enum representation of a Git file change in Aurora Editor.
@available(macOS, deprecated, message: "We use the new AppFileStatus protocol")
enum FileStatusKind: String {
    case new = "New"
    case modified = "Modified"
    case deleted = "Deleted"
    case copied = "Copied"
    case renamed = "Renamed"
    case conflicted = "Conflicted"
    case untracked = "Untracked"
}

/// The porcelain status for an unmerged entry
@available(macOS, deprecated, message: "We use the new AppFileStatus protocol")
func untrackedEntry() -> String {
    return "untracked"
}
