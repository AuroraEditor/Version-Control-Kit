//
//  FileChange.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public class FileChange {
    let id: String
    let path: String
    let status: AppFileStatus

    public init(path: String,
                status: AppFileStatus) {
        self.path = path
        self.status = status

        var fileId: String = ""

        // Generate a unique identifier based on the status and path.
        if let plainStatus = status as? PlainFileStatus {
            fileId = "plain+\(plainStatus.kind)+\(path)"
        } else if let copiedOrRenamedStatus = status as? CopiedOrRenamedFileStatus {
            fileId = "copiedOrRenamed+\(copiedOrRenamedStatus.oldPath)->\(path)"
        } else if status is ConflictsWithMarkers {
            fileId = "conflictsWithMarkers+\(path)"
        } else if status is ManualConflict {
            fileId = "manualConflict+\(path)"
        } else if status is UntrackedFileStatus {
            fileId = "untracked+\(path)"
        } else {
            print("Unknown AppFileStatus type")
        }

        self.id = fileId
    }
}
