//
//  RebaseResult.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

/// The app-specific results from attempting to rebase a repository.
enum RebaseResult {
    /// Git completed the rebase without reporting any errors, and the caller can signal success to the user.
    case completedWithoutError

    /// Git completed the rebase without reporting any errors, \
    /// but the branch was already up to date and there was nothing to do.
    case alreadyUpToDate

    /// The rebase encountered conflicts while attempting to rebase, \
    /// and these need to be resolved by the user before the rebase can continue.
    case conflictsEncountered

    /// The rebase was not able to continue as tracked files were not staged in the index.
    case outstandingFilesNotStaged

    /// The rebase was not attempted because it could not check the status of the repository. \
    /// The caller needs to confirm the repository is in a usable state.
    case aborted

    /// An unexpected error as part of the rebase flow was caught and handled.
    ///
    /// Check the logs to find the relevant Git details.
    case error
}
