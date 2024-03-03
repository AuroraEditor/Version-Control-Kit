//
//  GitShell.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public struct GitShell {

    public init() {}

    /**
     Executes a Git command with specified arguments in a given path and captures the result.

     - Parameters:
     - args: An array of Git command-line arguments to be passed to the Git command.
     - path: The path to the Git repository where the command should be executed.
     - name: A name or description of the command (used for logging or identification).
     - options: An optional set of Git execution options.

     - Returns: An `IGitResult` containing the result of the Git command execution.

     - Throws: An error if the Git command execution encounters issues.

     - Note: This function launches a Git process with the specified arguments and captures its \
             standard output and standard error. It sets the process's environment to ensure \
             consistent output formatting. If the command exits with a non-zero status code, it throws an error. \
             The function returns an `IGitResult` object containing the standard output, standard error, exit code, \
             and other details of the command execution.

     */
    @discardableResult
    public func git( // swiftlint:disable:this function_body_length cyclomatic_complexity
        args: [String],
        path: URL,
        name: String,
        options: IGitExecutionOptions? = nil
    ) throws -> IGitResult {
        var stdout = ""
        var stderr = ""

        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["git"] + args
        process.currentDirectoryPath = path.relativePath

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let environment = ProcessInfo.processInfo.environment

        // Set TERM to 'dumb' in the environment
        var gitEnvironment = environment
        gitEnvironment["TERM"] = "dumb"

        if let environment = options?.env {
            process.environment = environment
        }

        process.environment = gitEnvironment

        process.launch()

        let commandLineURL = "/usr/bin/env git " + args.joined(separator: " ")
        print("Command Line URL: \(commandLineURL)")

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: stdoutData, encoding: .utf8) {
            stdout = output
        }

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        if let errorOutput = String(data: stderrData, encoding: .utf8) {
            stderr = errorOutput
        }

        process.waitUntilExit()

        let combinedOuput = stdout + stderr

        print("Function: \(name), Output: \(stdout)")

        let result = IGitResult(stdout: stdout,
                                stderr: stderr,
                                exitCode: Int(process.terminationStatus),
                                gitError: nil,
                                gitErrorDescription: nil,
                                combinedOutput: stdout + stderr,
                                path: path.relativePath.escapedWhiteSpaces())

        let exitCode = result.exitCode
        var gitError: GitError?
        let acceptableExitCode = options?.successExitCodes != nil
            ? options?.successExitCodes?.contains(exitCode)
            : false

        if !acceptableExitCode! {
            gitError = parseError(stderr: result.stderr)
            if gitError == nil {
                gitError = parseError(stderr: result.stdout)
            }
        }

        let gitErrorDescription = gitError != nil ? getDescriptionError(gitError!) : nil

        var gitResult = IGitResult(stdout: stdout,
                                   stderr: stderr,
                                   exitCode: exitCode,
                                   gitError: gitError,
                                   gitErrorDescription: gitErrorDescription,
                                   combinedOutput: combinedOuput,
                                   path: path.relativePath.escapedWhiteSpaces())

        var acceptableError = true

        if gitError != nil && options?.expectedErrors != nil {
            acceptableError = ((options?.expectedErrors?.contains(gitError!)) != nil)
        }

        if (gitError != nil && acceptableError) || acceptableError {
            return gitResult
        }

        var errorMessage = [String]()

        errorMessage.append("`git \(args.joined(separator: " "))` exited with an unexpected code: \(exitCode)")

        if !result.stdout.isEmpty {
            errorMessage.append("stdout:")
            errorMessage.append(result.stdout)
        }

        if !result.stderr.isEmpty {
            errorMessage.append("stderr:")
            errorMessage.append(result.stderr)
        }

        if let gitError = gitError {
            errorMessage.append("(The error was parsed as \(gitError): \(gitErrorDescription ?? ""))")
        }

        let errorString = errorMessage.joined(separator: "\n")

        print(errorMessage.joined(separator: "\n"))

        if gitError == GitError.PushWithFileSizeExceedingLimit {
            let result = getFileFromExceedsError(error: errorMessage.joined())
            let files = result.joined(separator: "\n")

            if !files.isEmpty {
                gitResult.gitErrorDescription! += "\n\nFile causing error:\n\n" + files
            }
        }

        throw GitErrorParser(result: gitResult,
                             args: args)
    }

    /**
     Parses Git error messages from the standard error output.

     - Parameter stderr: The standard error output of a Git command.

     - Returns: A `GitError` enum value if an error is detected in the standard error output; otherwise, `nil`.

     - Note: This function checks the standard error output for error messages using a set of regular \
             expressions defined in `gitErrorRegexes`. If a matching error message is found, it returns \
             the corresponding `GitError` value. If no match is found, it returns `nil`.

     */
    func parseError(stderr: String) -> GitError? {
        for (regexPattern, error) in gitErrorRegexes {
            if let regex = try? NSRegularExpression(pattern: regexPattern) {
                if regex.firstMatch(in: stderr, range: NSRange(stderr.startIndex..., in: stderr)) != nil {
                    return error
                }
            }
        }
        return nil
    }

    private func getDescriptionError(_ error: GitError) -> String? { // swiftlint:disable:this function_body_length
        switch error {
        case .SSHKeyAuditUnverified:
            return "The SSH key is unverified."
        case .RemoteDisconnection:
            return "The remote disconnected. Check your Internet connection and try again."
        case .HostDown:
            return "The host is down. Check your Internet connection and try again."
        case .RebaseConflicts:
            return "We found some conflicts while trying to rebase. Please resolve the conflicts before continuing."
        case .MergeConflicts:
            return "We found some conflicts while trying to merge. Please resolve the conflicts and commit the changes."
        case .HTTPSRepositoryNotFound, .SSHRepositoryNotFound:
            // swiftlint:disable:next line_length
            return "The repository does not seem to exist anymore. You may not have access, or it may have been deleted or renamed."
        case .PushNotFastForward:
            return "The repository has been updated since you last pulled. Try pulling before pushing."
        case .BranchDeletionFailed:
            return "Could not delete the branch. It was probably already deleted."
        case .DefaultBranchDeletionFailed:
            return "The branch is the repository's default branch and cannot be deleted."
        case .RevertConflicts:
            return "To finish reverting, please merge and commit the changes."
        case .EmptyRebasePatch:
            return "There aren’t any changes left to apply."
        case .NoMatchingRemoteBranch:
            return "There aren’t any remote branches that match the current branch."
        case .NothingToCommit:
            return "There are no changes to commit."
        case .NoSubmoduleMapping:
            // swiftlint:disable:next line_length
            return "A submodule was removed from .gitmodules, but the folder still exists in the repository. Delete the folder, commit the change, then try again."
        case .SubmoduleRepositoryDoesNotExist:
            return "A submodule points to a location which does not exist."
        case .InvalidSubmoduleSHA:
            return "A submodule points to a commit which does not exist."
        case .LocalPermissionDenied:
            return "Permission denied."
        case .InvalidMerge:
            return "This is not something we can merge."
        case .InvalidRebase:
            return "This is not something we can rebase."
        case .NonFastForwardMergeIntoEmptyHead:
            return "The merge you attempted is not a fast-forward, so it cannot be performed on an empty branch."
        case .PatchDoesNotApply:
            return "The requested changes conflict with one or more files in the repository."
        case .BranchAlreadyExists:
            return "A branch with that name already exists."
        case .BadRevision:
            return "Bad revision."
        case .NotAGitRepository:
            return "This is not a git repository."
        case .ProtectedBranchForcePush:
            return "This branch is protected from force-push operations."
        case .ProtectedBranchRequiresReview:
            // swiftlint:disable:next line_length
            return "This branch is protected and any changes require an approved review. Open a pull request with changes targeting this branch instead."
        case .PushWithFileSizeExceedingLimit:
            // swiftlint:disable:next line_length
            return "The push operation includes a file which exceeds GitHub's file size restriction of 100MB. Please remove the file from history and try again."
        case .HexBranchNameRejected:
            // swiftlint:disable:next line_length
            return "The branch name cannot be a 40-character string of hexadecimal characters, as this is the format that Git uses for representing objects."
        case .ForcePushRejected:
            return "The force push has been rejected for the current branch."
        case .InvalidRefLength:
            return "A ref cannot be longer than 255 characters."
        case .CannotMergeUnrelatedHistories:
            return "Unable to merge unrelated histories in this repository."
        case .PushWithPrivateEmail:
            // swiftlint:disable:next line_length
            return "Cannot push these commits as they contain an email address marked as private on GitHub. To push anyway, visit https://github.com/settings/emails, uncheck 'Keep my email address private', then switch back to GitHub Desktop to push your commits. You can then enable the setting again."
        case .LFSAttributeDoesNotMatch:
            return "Git LFS attribute found in global Git configuration does not match the expected value."
        case .ProtectedBranchDeleteRejected:
            return "This branch cannot be deleted from the remote repository because it is marked as protected."
        case .ProtectedBranchRequiredStatus:
            return "The push was rejected by the remote server because a required status check has not been satisfied."
        case .BranchRenameFailed:
            return "The branch could not be renamed."
        case .PathDoesNotExist:
            return "The path does not exist on disk."
        case .InvalidObjectName:
            return "The object was not found in the Git repository."
        case .OutsideRepository:
            return "This path is not a valid path inside the repository."
        case .LockFileAlreadyExists:
            return "A lock file already exists in the repository, which blocks this operation from completing."
        case .NoMergeToAbort:
            return "There is no merge in progress, so there is nothing to abort."
        case .NoExistingRemoteBranch:
            return "The remote branch does not exist."
        case .LocalChangesOverwritten:
            // swiftlint:disable:next line_length
            return "Unable to switch branches as there are working directory changes that would be overwritten. Please commit or stash your changes."
        case .UnresolvedConflicts:
            return "There are unresolved conflicts in the working directory."
        case .ConfigLockFileAlreadyExists, .RemoteAlreadyExists, .TagAlreadyExists,
                .MergeWithLocalChanges, .RebaseWithLocalChanges, .GPGFailedToSignData,
                .ConflictModifyDeletedInBranch, .MergeCommitNoMainlineOption,
                .UnsafeDirectory, .PathExistsButNotInRef:
            return nil
        default:
            return "Unknown error: \(error)"

        }
    }

    func getFileFromExceedsError(error: String) -> [String] {
        do {
            let beginRegex = try NSRegularExpression(
                pattern: "(^remote:\\serror:\\sFile\\s)",
                options: []
            )
            let endRegex = try NSRegularExpression(
                pattern: "(;\\sthis\\sexceeds\\sGitHub's\\sfile\\ssize\\slimit\\sof\\s100.00\\sMB)",
                options: []
            )

            let beginMatches = beginRegex.matches(
                in: error,
                options: [],
                range: NSRange(error.startIndex..., in: error)
            )
            let endMatches = endRegex.matches(
                in: error,
                options: [],
                range: NSRange(error.startIndex..., in: error)
            )

            if beginMatches.count != endMatches.count {
                return []
            }

            var files: [String] = []

            for (beginMatch, endMatch) in zip(beginMatches, endMatches) {
                let from = error.index(error.startIndex, offsetBy: beginMatch.range.upperBound)
                let to = error.index(error.startIndex, offsetBy: endMatch.range.lowerBound)
                var file = String(error[from..<to])
                file = file.replacingOccurrences(of: "is ", with: "(")
                file += ")"
                files.append(file)
            }

            return files
        } catch {
            return []
        }
    }
}
