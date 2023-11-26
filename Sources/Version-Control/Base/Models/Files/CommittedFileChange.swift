//
//  CommittedFileChange.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

class CommittedFileChange: FileChange {
    let commitish: String
    let parentCommitish: String

    init(path: String, 
         status: AppFileStatus,
         commitish: String, 
         parentCommitish: String) {
        self.commitish = commitish
        self.parentCommitish = parentCommitish
        super.init(path: path, status: status)
    }
}
