//
//  AppFileStatus.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public enum GitStatusEntry: String, Codable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case unchanged = "."
    case untracked = "?"
    case ignored = "!"
    case updatedButUnmerged = "U"
}

public enum AppFileStatusKind: String, Codable {
    case new = "New"
    case modified = "Modified"
    case deleted = "Deleted"
    case copied = "Copied"
    case renamed = "Renamed"
    case conflicted = "Conflicted"
    case untracked = "Untracked"
}

public struct SubmoduleStatus: Codable {
    let commitChanged: Bool
    let modifiedChanges: Bool
    let untrackedChanges: Bool
}

public struct PlainFileStatus: AppFileStatus, Codable {
    public var kind: AppFileStatusKind
    public var submoduleStatus: SubmoduleStatus?
}

public struct CopiedOrRenamedFileStatus: AppFileStatus, Codable {
    public var kind: AppFileStatusKind
    let oldPath: String
    public var submoduleStatus: SubmoduleStatus?
}

// MARK: - Conflicted 
public protocol ConflictedFileStatus: AppFileStatus {}

public struct ConflictsWithMarkers: ConflictedFileStatus, Codable {
    public var kind: AppFileStatusKind
    let entry: TextConflictEntry
    let conflictMarkerCount: Int
    public var submoduleStatus: SubmoduleStatus?
}

public struct ManualConflict: ConflictedFileStatus, Codable {
    public var kind: AppFileStatusKind
    let entry: ManualConflictEntry
    public var submoduleStatus: SubmoduleStatus?
}

public func isConflictedFileStatus(_ appFileStatus: AppFileStatus) -> Bool {
    return appFileStatus.kind == .conflicted
}

public func isConflictWithMarkers(_ conflictedFileStatus: ConflictedFileStatus) -> Bool {
    return conflictedFileStatus is ConflictsWithMarkers
}

public func isManualConflict(_ conflictedFileStatus: ConflictedFileStatus) -> Bool {
    return conflictedFileStatus is ManualConflict
}

public struct UntrackedFileStatus: AppFileStatus, Codable {
    public var kind: AppFileStatusKind
    public var submoduleStatus: SubmoduleStatus?
}

public protocol AppFileStatus: Codable {
    var kind: AppFileStatusKind { get set }
    var submoduleStatus: SubmoduleStatus? { get set }
}

public enum UnmergedEntrySummary: String, Codable {
    case AddedByUs = "added-by-us"
    case DeletedByUs = "deleted-by-us"
    case AddedByThem = "added-by-them"
    case DeletedByThem = "deleted-by-them"
    case BothDeleted = "both-deleted"
    case BothAdded = "both-added"
    case BothModified = "both-modified"
}

public struct ManualConflictDetails: Codable {
    let submoduleStatus: SubmoduleStatus?
    let action: UnmergedEntrySummary
    let us: GitStatusEntry
    let them: GitStatusEntry
}

public struct TextConflictDetails: Codable {
    let action: UnmergedEntrySummary
    let us: GitStatusEntry
    let them: GitStatusEntry
}

// MARK: - Entry Conformities

protocol FileEntry {
    var kind: String { get }
    var submoduleStatus: SubmoduleStatus? { get }
}

protocol UnmergedEntry {}

public struct TextConflictEntry: Codable, FileEntry, UnmergedEntry {
    let kind: String = "conflicted"
    let submoduleStatus: SubmoduleStatus?
    let details: TextConflictDetails
}

public struct ManualConflictEntry: Codable, FileEntry, UnmergedEntry {
    let kind: String = "conflicted"
    let submoduleStatus: SubmoduleStatus?
    let details: ManualConflictDetails
}

struct UntrackedEntry: FileEntry {
    let kind: String = "untracked"
    let submoduleStatus: SubmoduleStatus?
}

struct RenamedOrCopiedEntry: FileEntry {
    enum RenamedOrCopiedEntryType: String {
        case renamed
        case copied
    }

    let kind: String
    let index: GitStatusEntry?
    let workingTree: GitStatusEntry?
    let submoduleStatus: SubmoduleStatus?

    init(kind: RenamedOrCopiedEntryType,
         index: GitStatusEntry?,
         workingTree: GitStatusEntry?,
         submoduleStatus: SubmoduleStatus?) {
        self.kind = kind.rawValue
        self.index = index
        self.workingTree = workingTree
        self.submoduleStatus = submoduleStatus
    }

}

struct OrdinaryEntry: FileEntry {

    enum OrdinaryEntryType {
        case added
        case modified
        case deleted
    }

    let kind: String = "ordinary"
    let type: OrdinaryEntryType
    let index: GitStatusEntry?
    let workingTree: GitStatusEntry?
    let submoduleStatus: SubmoduleStatus?
}
