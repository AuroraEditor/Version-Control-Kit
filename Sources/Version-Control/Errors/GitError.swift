//
//  GitError.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

// The git errors which can be parsed from failed git commands.
public enum GitError {
    case SSHKeyAuditUnverified
    case SSHAuthenticationFailed
    case SSHPermissionDenied
    case HTTPSAuthenticationFailed
    case RemoteDisconnection
    case HostDown
    case RebaseConflicts
    case MergeConflicts
    case HTTPSRepositoryNotFound
    case SSHRepositoryNotFound
    case PushNotFastForward
    case BranchDeletionFailed
    case DefaultBranchDeletionFailed
    case RevertConflicts
    case EmptyRebasePatch
    case NoMatchingRemoteBranch
    case NoExistingRemoteBranch
    case NothingToCommit
    case NoSubmoduleMapping
    case SubmoduleRepositoryDoesNotExist
    case InvalidSubmoduleSHA
    case LocalPermissionDenied
    case InvalidMerge
    case InvalidRebase
    case NonFastForwardMergeIntoEmptyHead
    case PatchDoesNotApply
    case BranchAlreadyExists
    case BadRevision
    case NotAGitRepository
    case CannotMergeUnrelatedHistories
    case LFSAttributeDoesNotMatch
    case BranchRenameFailed
    case PathDoesNotExist
    case InvalidObjectName
    case OutsideRepository
    case LockFileAlreadyExists
    case NoMergeToAbort
    case LocalChangesOverwritten
    case UnresolvedConflicts
    case GPGFailedToSignData
    case ConflictModifyDeletedInBranch
    // Start of GitHub-specific error codes
    case PushWithFileSizeExceedingLimit
    case HexBranchNameRejected
    case ForcePushRejected
    case InvalidRefLength
    case ProtectedBranchRequiresReview
    case ProtectedBranchForcePush
    case ProtectedBranchDeleteRejected
    case ProtectedBranchRequiredStatus
    case PushWithPrivateEmail
    // End of GitHub-specific error codes
    case ConfigLockFileAlreadyExists
    case RemoteAlreadyExists
    case TagAlreadyExists
    case MergeWithLocalChanges
    case RebaseWithLocalChanges
    case MergeCommitNoMainlineOption
    case UnsafeDirectory
    case PathExistsButNotInRef
}

// A mapping from regexes to the git error they identify.
public let gitErrorRegexes: [String: GitError] = [
    "ERROR: ([\\s\\S]+?)\\n+\\[EPOLICYKEYAGE\\]\\n+fatal: Could not read from remote repository.":
            .SSHKeyAuditUnverified,
    "fatal: Authentication failed for 'https://":
            .HTTPSAuthenticationFailed,
    "fatal: Authentication failed": .SSHAuthenticationFailed,
    "fatal: Could not read from remote repository.": .SSHPermissionDenied,
    "The requested URL returned error: 403": .HTTPSAuthenticationFailed,
    "fatal: [Tt]he remote end hung up unexpectedly": .RemoteDisconnection,
    "fatal: unable to access '(.+)': Failed to connect to (.+): Host is down":
            .HostDown,
    "Cloning into '(.+)'...\nfatal: unable to access '(.+)': Could not resolve host: (.+)":
            .HostDown,
    "Resolve all conflicts manually, mark them as resolved with":
            .RebaseConflicts,
    "(Merge conflict|Automatic merge failed; fix conflicts and then commit the result)":
            .MergeConflicts,
    "fatal: repository '(.+)' not found": .HTTPSRepositoryNotFound,
    "ERROR: Repository not found": .SSHRepositoryNotFound,
    "\\((non-fast-forward|fetch first)\\)\nerror: failed to push some refs to '.*'":
            .PushNotFastForward,
    "error: unable to delete '(.+)': remote ref does not exist":
            .BranchDeletionFailed,
    "\\[remote rejected\\] (.+) \\(deletion of the current branch prohibited\\)":
            .DefaultBranchDeletionFailed,
    // swiftlint:disable:next line_length
    "error: could not revert .*\nhint: after resolving the conflicts, mark the corrected paths\nhint: with 'git add <paths>' or 'git rm <paths>'\nhint: and commit the result with 'git commit'":
            .RevertConflicts,
    "Applying: .*\nNo changes - did you forget to use 'git add'\\?\nIf there is nothing left to stage, chances are that something else\n.*":
            .EmptyRebasePatch,
    "There are no candidates for (rebasing|merging) among the refs that you just fetched.\nGenerally this means that you provided a wildcard refspec which had no\nmatches on the remote end.":
            .NoMatchingRemoteBranch,
    "Your configuration specifies to merge with the ref '(.+)'\nfrom the remote, but no such ref was fetched.":
            .NoExistingRemoteBranch,
    "nothing to commit": .NothingToCommit,
    "[Nn]o submodule mapping found in .gitmodules for path '(.+)'":
            .NoSubmoduleMapping,
    "fatal: repository '(.+)' does not exist\nfatal: clone of '.+' into submodule path '(.+)' failed":
            .SubmoduleRepositoryDoesNotExist,
    "Fetched in submodule path '(.+)', but it did not contain (.+). Direct fetching of that commit failed.":
            .InvalidSubmoduleSHA,
    "fatal: could not create work tree dir '(.+)'.*: Permission denied":
            .LocalPermissionDenied,
    "merge: (.+) - not something we can merge": .InvalidMerge,
    "invalid upstream (.+)": .InvalidRebase,
    "fatal: Non-fast-forward commit does not make sense into an empty head":
            .NonFastForwardMergeIntoEmptyHead,
    "error: (.+): (patch does not apply|already exists in working directory)":
            .PatchDoesNotApply,
    "fatal: [Aa] branch named '(.+)' already exists.?":
            .BranchAlreadyExists,
    "fatal: bad revision '(.*)'": .BadRevision,
    "fatal: [Nn]ot a git repository \\(or any of the parent directories\\): (.*)":
            .NotAGitRepository,
    "fatal: refusing to merge unrelated histories":
            .CannotMergeUnrelatedHistories,
    "The .+ attribute should be .+ but is .+": .LFSAttributeDoesNotMatch,
    "fatal: Branch rename failed": .BranchRenameFailed,
    "fatal: path '(.+)' does not exist .+": .PathDoesNotExist,
    "fatal: invalid object name '(.+)'.": .InvalidObjectName,
    "fatal: .+: '(.+)' is outside repository": .OutsideRepository,
    "Another git process seems to be running in this repository, e.g.":
            .LockFileAlreadyExists,
    "fatal: There is no merge to abort": .NoMergeToAbort,
    "error: (?:Your local changes to the following|The following untracked working tree) files would be overwritten by checkout:":
            .LocalChangesOverwritten,
    "You must edit all merge conflicts and then\nmark them as resolved using git add|fatal: Exiting because of an unresolved conflict":
            .UnresolvedConflicts,
    "error: gpg failed to sign the data": .GPGFailedToSignData,
    "CONFLICT \\(modify/delete\\): (.+) deleted in (.+) and modified in (.+)":
            .ConflictModifyDeletedInBranch,
    // GitHub-specific errors
    "error: GH001: ": .PushWithFileSizeExceedingLimit,
    "error: GH002: ": .HexBranchNameRejected,
    "error: GH003: Sorry, force-pushing to (.+) is not allowed.":
            .ForcePushRejected,
    "error: GH005: Sorry, refs longer than (.+) bytes are not allowed":
            .InvalidRefLength,
    "error: GH006: Protected branch update failed for (.+)\nremote: error: At least one approved review is required":
            .ProtectedBranchRequiresReview,
    "error: GH006: Protected branch update failed for (.+)\nremote: error: Cannot force-push to a protected branch":
            .ProtectedBranchForcePush,
    "error: GH006: Protected branch update failed for (.+).\nremote: error: Cannot delete a protected branch":
            .ProtectedBranchDeleteRejected,
    "error: GH006: Protected branch update failed for (.+).\nremote: error: Required status check \"(.+)\" is expected":
            .ProtectedBranchRequiredStatus,
    "error: GH007: Your push would publish a private email address.":
            .PushWithPrivateEmail,
    "error: could not lock config file (.+): File exists":
            .ConfigLockFileAlreadyExists,
    "error: remote (.+) already exists.": .RemoteAlreadyExists,
    "fatal: tag '(.+)' already exists": .TagAlreadyExists,
    "error: Your local changes to the following files would be overwritten by merge:\n":
            .MergeWithLocalChanges,
    "error: cannot (pull with rebase|rebase): You have unstaged changes\\.\n\\s*error: [Pp]lease commit or stash them\\.":
            .RebaseWithLocalChanges,
    "error: commit (.+) is a merge but no -m option was given":
            .MergeCommitNoMainlineOption,
    "fatal: detected dubious ownership in repository at (.+)":
            .UnsafeDirectory,
    "fatal: path '(.+)' exists on disk, but not in '(.+)'":
            .PathExistsButNotInRef
    ]

// The error code for when git cannot be found. This most likely indicates a
// problem with dugite itself.
public let GitNotFoundErrorCode = "git-not-found-error"

// The error code for when the path to a repository doesn't exist.
public let RepositoryDoesNotExistErrorCode = "repository-does-not-exist-error"
