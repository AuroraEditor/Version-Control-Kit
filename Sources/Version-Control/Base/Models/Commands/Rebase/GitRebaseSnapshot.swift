//
//  GitRebaseSnapshot.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

struct GitRebaseSnapshot {
    let commits: [Commit]
    let progress: MultiCommitOperationProgress
}
