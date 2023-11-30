//
//  AppFileStatus.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public enum GitStatusEntry: String {
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

public enum AppFileStatusKind {
    case new
    case modified
    case deleted
    case copied
    case renamed
    case conflicted
    case untracked
}

public struct SubmoduleStatus {
    let commitChanged: Bool
    let modifiedChanges: Bool
    let untrackedChanges: Bool
}

public struct PlainFileStatus: AppFileStatus {
    public var kind: AppFileStatusKind
    public var submoduleStatus: SubmoduleStatus?
}

public struct CopiedOrRenamedFileStatus: AppFileStatus {
    public var kind: AppFileStatusKind
    let oldPath: String
    public var submoduleStatus: SubmoduleStatus?
}

// MARK: - Conflicted 
public protocol ConflictedFileStatus: AppFileStatus {}

public struct ConflictsWithMarkers: ConflictedFileStatus {
    public var kind: AppFileStatusKind
    let entry: TextConflictEntry
    let conflictMarkerCount: Int
    public var submoduleStatus: SubmoduleStatus?
}

public struct ManualConflict: ConflictedFileStatus {
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

public struct UntrackedFileStatus: AppFileStatus {
    public var kind: AppFileStatusKind
    public var submoduleStatus: SubmoduleStatus?
}

public protocol AppFileStatus {
    var kind: AppFileStatusKind { get set }
    var submoduleStatus: SubmoduleStatus? { get set }
}

public enum UnmergedEntrySummary: String {
    case AddedByUs = "added-by-us"
    case DeletedByUs = "deleted-by-us"
    case AddedByThem = "added-by-them"
    case DeletedByThem = "deleted-by-them"
    case BothDeleted = "both-deleted"
    case BothAdded = "both-added"
    case BothModified = "both-modified"
}

public struct ManualConflictDetails {
    let submoduleStatus: SubmoduleStatus?
    let action: UnmergedEntrySummary
    let us: GitStatusEntry
    let them: GitStatusEntry
}

public struct TextConflictDetails {
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

public struct TextConflictEntry: FileEntry, UnmergedEntry {
    let kind: String = "conflicted"
    let submoduleStatus: SubmoduleStatus?
    let details: TextConflictDetails
}

public struct ManualConflictEntry: FileEntry, UnmergedEntry {
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
        case renamed = "renamed"
        case copied = "copied"
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
