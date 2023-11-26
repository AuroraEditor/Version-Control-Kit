//
//  WorkingDirectoryStatus.swift
//
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

struct WorkingDirectoryStatus {
    let files: [WorkingDirectoryFileChange]
    let includeAll: Bool?

    init(files: [WorkingDirectoryFileChange], 
         includeAll: Bool? = true) {
        self.files = files
        self.includeAll = includeAll
    }

    // Computed property to create a map from file ID to index.
    private var fileIxById: [String: Int] {
        var map = [String: Int]()
        for (index, file) in files.enumerated() {
            map[file.id] = index
        }
        return map
    }

    // Static function to create a new instance with files.
    static func fromFiles(_ files: [WorkingDirectoryFileChange]) -> WorkingDirectoryStatus {
        return WorkingDirectoryStatus(files: files, includeAll: getIncludeAllState(files))
    }

    // Function to update the include state of all files.
    func withIncludeAllFiles(includeAll: Bool) -> WorkingDirectoryStatus {
        let newFiles = files.map { $0.withIncludeAll(include: includeAll) }
        return WorkingDirectoryStatus(files: newFiles, includeAll: includeAll)
    }

    // Function to find a file with a given ID.
    func findFileWithID(_ id: String) -> WorkingDirectoryFileChange? {
        guard let index = fileIxById[id] else { return nil }
        return files.indices.contains(index) ? files[index] : nil
    }

    // Function to find the index of a file with a given ID.
    func findFileIndexByID(_ id: String) -> Int {
        return fileIxById[id] ?? -1
    }
}

func getIncludeAllState(_ files: [WorkingDirectoryFileChange]) -> Bool? {
    if files.isEmpty {
        return true
    }

    let allSelected = files.allSatisfy {
        $0.selection.getSelectionType() == .all
    }
    let noneSelected = files.allSatisfy {
        $0.selection.getSelectionType() == .none
    }

    if allSelected {
        return true
    } else if noneSelected {
        return false
    } else {
        return nil
    }
}
