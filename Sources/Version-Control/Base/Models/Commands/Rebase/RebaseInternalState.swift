//
//  RebaseInternalState.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

public struct RebaseInternalState {
    /// The branch containing commits that should be rebased
    let targetBranch: String
    /// The commit ID of the base branch, to be used as a starting point for the rebase.
    let baseBranchTip: String
    /// The commit ID of the target branch at the start of the rebase, which points to the original commit history.
    let originalBranchTip: String
}
