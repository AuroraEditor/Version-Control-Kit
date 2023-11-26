//
//  RebaseProgressOptions.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

struct RebaseProgressOptions {
    let commits: [Commit]
    let progressCallback: (MultiCommitOperationProgress) -> Void
}
