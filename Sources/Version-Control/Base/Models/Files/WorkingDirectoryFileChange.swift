//
//  WorkingDirectoryFileChange.swift
//
//
//  Created by Nanashi Li on 2023/11/13.
//

import Foundation

open class WorkingDirectoryFileChange: FileChange {
    let selection: DiffSelection

    public init(path: String,
                status: AppFileStatus?,
                selection: DiffSelection) {
        self.selection = selection
        super.init(path: path, status: status)
    }

    func withIncludeAll(include: Bool) -> WorkingDirectoryFileChange {
        let newSelection = include ? selection.withSelectAll() : selection.withSelectNone()
        return withSelection(newSelection)
    }

    func withSelection(_ selection: DiffSelection) -> WorkingDirectoryFileChange {
        return WorkingDirectoryFileChange(path: self.path, status: self.status, selection: selection)
    }
}
