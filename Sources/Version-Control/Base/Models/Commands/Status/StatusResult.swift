//
//  StatusResult.swift
//
//
//  Created by Nanashi Li on 2023/11/21.
//

import Foundation

struct StatusResult {
    /// The name of the current branch.
    let currentBranch: String?

    /// The name of the current upstream branch.
    let currentUpstreamBranch: String?

    /// The SHA of the tip commit of the current branch.
    let currentTip: String?

    /// Information on how many commits ahead and behind the currentBranch is compared to the currentUpstreamBranch.
    let branchAheadBehind: IAheadBehind?

    /// True if the repository exists at the given location.
    let exists: Bool

    /// True if the repository is in a conflicted state.
    let mergeHeadFound: Bool

    /// True if a merge --squash operation is started.
    let squashMsgFound: Bool

    /// Details about the rebase operation, if found.
    let rebaseInternalState: RebaseInternalState?

    /// True if the repository is in a cherry-picking state.
    let isCherryPickingHeadFound: Bool

    /// The absolute path to the repository's working directory.
    let workingDirectory: WorkingDirectoryStatus

    /// Whether conflicting files are present in the repository.
    let doConflictedFilesExist: Bool
}
