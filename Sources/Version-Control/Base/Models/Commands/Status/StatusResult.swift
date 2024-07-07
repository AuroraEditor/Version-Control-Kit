//
//  StatusResult.swift
//
//
//  Created by Nanashi Li on 2023/11/21.
//

import Foundation

public struct StatusResult {
    /// The name of the current branch.
    public let currentBranch: String?

    /// The name of the current upstream branch.
    public let currentUpstreamBranch: String?

    /// The SHA of the tip commit of the current branch.
    public let currentTip: String?

    /// Information on how many commits ahead and behind the currentBranch is compared to the currentUpstreamBranch.
    public let branchAheadBehind: IAheadBehind?

    /// True if the repository exists at the given location.
    public let exists: Bool

    /// True if the repository is in a conflicted state.
    public let mergeHeadFound: Bool

    /// True if a merge --squash operation is started.
    public let squashMsgFound: Bool

    /// Details about the rebase operation, if found.
    public let rebaseInternalState: RebaseInternalState?

    /// True if the repository is in a cherry-picking state.
    public let isCherryPickingHeadFound: Bool

    /// The absolute path to the repository's working directory.
    public let workingDirectory: WorkingDirectoryStatus

    /// Whether conflicting files are present in the repository.
    public let doConflictedFilesExist: Bool
}
