//
//  Stage.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitStage {

    public init() {}

    /// Stages a file with the given manual resolution method.
    /// Useful for resolving binary conflicts at commit-time.
    func stageManualConflictResolution(directoryURL: URL,
                                       file: WorkingDirectoryFileChange,
                                       manualResolution: ManualConflictResolution) throws {
        guard let fileStatus = file.status else {
            print("File status is nil")
            return
        }
        if !isConflictedFileStatus(fileStatus) {
            print("Tried to manually resolve unconflicted file (\(file.path))")
            return
        }

        guard let conflictedStatus = fileStatus as? ConflictsWithMarkers else {
            print("Failed to cast to ConflictsWithMarkers")
            return
        }

        if isConflictWithMarkers(conflictedStatus) && conflictedStatus.conflictMarkerCount == 0 {
            // If the file was manually resolved, no further action is required.
            return
        }

        let chosen = manualResolution == .theirs
            ? conflictedStatus.entry.details.them
            : conflictedStatus.entry.details.us

        let addedInBoth = conflictedStatus.entry.details.us == GitStatusEntry.added
            && conflictedStatus.entry.details.them == GitStatusEntry.added

        if chosen == .updatedButUnmerged || addedInBoth {
            try GitCheckout().checkoutConflictedFile(directoryURL: directoryURL,
                                                     file: file,
                                                     resolution: manualResolution)
        }

        switch chosen {
        case .deleted:
            try RM().removeConflictedFile(directoryURL: directoryURL,
                                          file: file)
        case .added, .updatedButUnmerged:
            try Add().addConflictedFile(directoryURL: directoryURL,
                                        file: file)
        default:
            fatalError("Unaccounted for git status entry possibility")
        }
    }
}
