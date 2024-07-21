//
//  Diff.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitDiff { // swiftlint:disable:this type_body_length

    private let binaryListRegex = "/-\t-\t(?:\0.+\0)?([^\0]*)/gi"

    /// Where `MaxDiffBufferSize` is a hard limit, this is a suggested limit. Diffs
    /// bigger than this _could_ be displayed but it might cause some slowness.
    let maxReasonableDiffSize = 70_000_000 / 16 // ~4.375MB in decimal

    /// The longest line length we should try to display. If a diff has a line longer
    /// than this, we probably shouldn't attempt it
    let maxCharactersPerLine = 5000

    public init() {}

    func isValidBuffer(_ buffer: String) -> Bool {
        return buffer.count < Int(70_000_000)
    }

    func isBufferTooLarge(_ buffer: String) -> Bool {
        return buffer.count >= Int(maxReasonableDiffSize)
    }

    /// Is the diff too large for us to reasonably represent?
    public func isDiffToLarge(diff: IRawDiff) -> Bool {
        for hunk in diff.hunks {
            for line in hunk.lines {
                // swiftlint:disable:next for_where
                if line.text.count > maxCharactersPerLine {
                    return true
                }
            }
        }
        return false
    }

    let imageFileExtensions: Set<String> = [
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".ico",
        ".webp",
        ".bmp",
        ".avif"
    ]

    /// Generates a diff for a file from a specified commit.
    ///
    /// This function constructs a `git log` command to produce a diff for the specified file from the given commit.
    /// The diff includes the changes made in that commit along with the raw patch data. It supports an option to
    /// ignore whitespace when generating the diff. If the file has been copied or renamed, additional path information
    /// is included in the command to track changes across file paths.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - file: A `FileChange` object representing the file to diff.
    ///   - commitish: A string representing the commit from which to generate the diff.
    ///   - hideWhitespaceInDiff: A Boolean value indicating whether to ignore whitespace changes in the diff.
    /// - Returns: An object conforming to the `IDiff` protocol that represents the generated diff.
    /// - Throws: An error if the git command fails or if the diff cannot be built.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = FileChange(path: "file.txt", status: .modified)
    /// let commitRef = "abc123"
    /// let diff = try getCommitDiff(directoryURL: directoryURL,
    ///                              file: fileChange,
    ///                              commitish: commitRef,
    ///                              hideWhitespaceInDiff: true)
    /// ```
    func getCommitDiff(directoryURL: URL,
                       file: FileChange,
                       commitish: String,
                       hideWhitespaceInDiff: Bool = false) throws -> IDiff {
        var args = [
            "log",
            commitish,
            "-m",
            "-1",
            "--first-parent",
            "--patch-with-raw",
            "-z",
            "--no-color",
            "--",
            file.path
        ]

        if hideWhitespaceInDiff {
            args.insert("-w", at: 1) // Insert "-w" right after the commitish
        }

        if let file = file.status as? CopiedOrRenamedFileStatus {
            if file.kind == .renamed || file.kind == .copied {
                args.append(file.oldPath)
            }
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        return try buildDiff(buffer: result.stdout,
                             directoryURL: directoryURL,
                             file: file,
                             oldestCommitish: commitish,
                             lineEndingChange: nil)
    }

    /// Calculates a diff for a file between the merge base of two branches and a specified commit.
    ///
    /// This function determines the merge base between the base branch and the comparison branch,
    /// and generates a diff for the specified file against the latest commit. It provides an option to
    /// ignore whitespace changes in the diff output. Additional handling is provided for files that
    /// have been copied or renamed.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - file: A `FileChange` object representing the file to diff.
    ///   - baseBranchName: The name of the base branch for the diff comparison.
    ///   - comparisonBranchName: The name of the comparison branch for the diff comparison.
    ///   - hideWhitespaceInDiff: A Boolean value indicating whether to ignore whitespace changes in the diff.
    ///   - latestCommit: The identifier of the latest commit for the comparison branch.
    /// - Returns: An object conforming to the `IDiff` protocol that represents the generated diff.
    /// - Throws: An error if the git command fails or if the diff cannot be built.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = FileChange(path: "file.txt", status: .modified)
    /// let baseBranch = "main"
    /// let comparisonBranch = "feature"
    /// let latestCommitRef = "def456"
    /// let diff = try getBranchMergeBaseDiff(directoryURL: directoryURL,
    ///                                       file: fileChange,
    ///                                       baseBranchName: baseBranch,
    ///                                       comparisonBranchName: comparisonBranch,
    ///                                       hideWhitespaceInDiff: true,
    ///                                       latestCommit: latestCommitRef)
    /// ```
    func getBranchMergeBaseDiff(directoryURL: URL,
                                file: FileChange,
                                baseBranchName: String,
                                comparisonBranchName: String,
                                hideWhitespaceInDiff: Bool = false,
                                latestCommit: String) throws -> IDiff {
        var args = [
            "diff",
            "--merge-base",
            baseBranchName,
            comparisonBranchName,
            "--patch-with-raw",
            "-z",
            "--no-color",
            "--",
            file.path
        ]

        if hideWhitespaceInDiff {
            args.insert("-w", at: args.count - 4) // Insert before "--patch-with-raw"
        }

        if let file = file.status as? CopiedOrRenamedFileStatus {
            if file.kind == .renamed || file.kind == .copied {
                args.append(file.oldPath)
            }
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        return try buildDiff(buffer: result.stdout,
                             directoryURL: directoryURL,
                             file: file,
                             oldestCommitish: latestCommit,
                             lineEndingChange: nil)
    }

    /// Computes a diff for a file across a specified range of commits.
    ///
    /// This function generates a diff for the specified file,
    /// comparing the changes from the parent of the oldest commit
    /// (or a null tree SHA if specified) to the latest commit in the given range. 
    /// It includes options to ignore whitespace
    /// in the diff output and to retry with a null tree SHA if the oldest commit has no parent.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - file: A `FileChange` object representing the file to diff.
    ///   - commits: An array of commit identifiers, from oldest to newest, to include in the diff.
    ///   - hideWhitespaceInDiff: A Boolean value indicating whether to ignore whitespace when generating the diff.
    ///   - useNullTreeSHA: A Boolean value indicating whether to use the null tree SHA as \
    ///                     the base for the oldest commit.
    /// - Returns: An object conforming to the `IDiff` protocol that represents the generated diff.
    /// - Throws: An error if the commit range is empty or invalid, or if the git command fails.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = FileChange(path: "file.txt", status: .modified)
    /// let commitRange = ["abc123", "def456"]
    /// let diff = try getCommitRangeDiff(directoryURL: directoryURL,
    ///                                   file: fileChange,
    ///                                   commits: commitRange,
    ///                                   hideWhitespaceInDiff: true)
    /// ```
    func getCommitRangeDiff(directoryURL: URL,
                            file: FileChange,
                            commits: [String],
                            hideWhitespaceInDiff: Bool = false,
                            useNullTreeSHA: Bool = false) throws -> IDiff {
        if commits.isEmpty {
            // FIXME: This should be a more specific error type
            // Domain: com.auroraeditor.versioncontrolkit.diff
            throw NSError(domain: "No commits to diff...", code: 0)
        }

        let oldestCommitRef = useNullTreeSHA ? DiffIndex().nilTreeSHA : "\(commits[0])^"
        guard let latestCommit = commits.last else {
            // FIXME: This should be a more specific error type
            // Domain: com.auroraeditor.versioncontrolkit.diff
            throw NSError(domain: "Invalid commit range", code: 0)
        }

        var args = [
            "diff",
            oldestCommitRef,
            latestCommit,
            "--patch-with-raw",
            "-z",
            "--no-color",
            "--",
            file.path
        ]

        if hideWhitespaceInDiff {
            args.insert("-w", at: 3)
        }

        if let renamed = file.status as? CopiedOrRenamedFileStatus {
            if renamed.kind == .renamed || renamed.kind == .copied {
                args.append(renamed.oldPath)
            }
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(expectedErrors: [GitError.BadRevision]))

        if result.gitError == GitError.BadRevision && useNullTreeSHA == false {
            return try getCommitRangeDiff(directoryURL: directoryURL,
                                          file: file,
                                          commits: commits,
                                          hideWhitespaceInDiff: hideWhitespaceInDiff,
                                          useNullTreeSHA: true)
        }

        return try buildDiff(buffer: result.stdout,
                             directoryURL: directoryURL,
                             file: file,
                             oldestCommitish: latestCommit,
                             lineEndingChange: nil)
    }

    /// Calculates the changeset between the merge base of two branches and a specific commit in a git repository.
    ///
    /// The function first determines the merge base between the specified base and comparison branches.
    /// It then constructs and executes a git diff command to compare the merge base with the latest commit
    /// of the comparison branch. The output of this command is parsed to produce the changeset data.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - baseBranchName: A string representing the name of the base branch.
    ///   - comparisonBranchName: A string representing the name of the branch to compare against the base branch.
    ///   - latestComparisonBranchCommitRef: A string representing the latest commit of the comparison branch.
    /// - Returns: An optional `IChangesetData` object representing the changeset, or nil if no merge base is found.
    /// - Throws: An error if the git command fails or if parsing the output encounters an error.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let baseBranch = "main"
    /// let comparisonBranch = "feature-branch"
    /// let latestCommitRef = "abc123def"
    /// let changesetData = try getBranchMergeBaseChangedFiles(directoryURL: directoryURL,
    ///                                                        baseBranchName: baseBranch,
    ///                                                        comparisonBranchName: comparisonBranch,
    ///                                                        latestComparisonBranchCommitRef: latestCommitRef)
    /// ```
    func getBranchMergeBaseChangedFiles(directoryURL: URL,
                                        baseBranchName: String,
                                        comparisonBranchName: String,
                                        latestComparisonBranchCommitRef: String) throws -> IChangesetData? {
        let baseArgs = [
            "diff",
            "--merge-base",
            baseBranchName,
            comparisonBranchName,
            "-C",
            "-M",
            "-z",
            "--raw",
            "--numstat",
            "--"
        ]

        guard let mergeBaseCommit = try Merge().getMergeBase(directoryURL: directoryURL,
                                                             firstCommitish: baseBranchName,
                                                             secondCommitish: comparisonBranchName) else {
            return nil
        }

        let result = try GitShell().git(args: baseArgs,
                                        path: directoryURL,
                                        name: #function)

        return try  GitLog().parseRawLogWithNumstat(stdout: result.stdout,
                                                    sha: latestComparisonBranchCommitRef,
                                                    parentCommitish: mergeBaseCommit)
    }

    /// Computes a changeset between a range of commits in a git repository.
    ///
    /// The function first checks to ensure that the array of commit SHAs is not empty.
    /// If the `useNullTreeSHA` flag is set, or if the oldest commit does not have a parent,
    /// the function uses the null tree SHA as a basis for the diff.
    /// Otherwise, it uses the parent of the oldest commit. It then constructs and executes
    /// a git diff command with the specified arguments. If an error occurs and `useNullTreeSHA`
    /// is not already set, it retries the command using the null tree SHA.
    /// Finally, it parses the raw log with numstat to produce the changeset data.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - shas: An array of strings representing the commit SHAs to include in the diff.
    ///   - useNullTreeSHA: A Boolean flag indicating whether to use the null tree SHA as the basis for the diff.
    /// - Returns: An `IChangesetData` object representing the changes between the commits.
    /// - Throws: An error if the SHA array is empty or if the git command fails.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let commitShas = ["abc123", "def456"]
    /// let changesetData = try getCommitRangeChangedFiles(directoryURL: directoryURL, shas: commitShas)
    /// ```
    func getCommitRangeChangedFiles(directoryURL: URL,
                                    shas: [String],
                                    useNullTreeSHA: Bool = false) throws -> IChangesetData {
        guard !shas.isEmpty else {
            throw NSError(
                domain: "com.auroraeditor.versioncontrolkit.git",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No commits to diff..."]
            )
        }

        let oldestCommitRef = useNullTreeSHA ? DiffIndex().nilTreeSHA : "\\(shas[0])^"
        let latestCommitRef = shas.last ?? "" // shas is never empty, so this is safe.

        let baseArgs = [
            "diff",
            oldestCommitRef,
            latestCommitRef,
            "-C",
            "-M",
            "-z",
            "--raw",
            "--numstat",
            "--"
        ]

        let result = try GitShell().git(args: baseArgs,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(expectedErrors: [GitError.BadRevision]))

        if let error = result.gitError, error == .BadRevision, !useNullTreeSHA {
            // Retry with the null tree SHA if the oldest commit does not have a parent.
            return try getCommitRangeChangedFiles(directoryURL: directoryURL,
                                                  shas: shas,
                                                  useNullTreeSHA: true)
        }

        return try GitLog().parseRawLogWithNumstat(stdout: result.stdout,
                                                   sha: latestCommitRef,
                                                   parentCommitish: oldestCommitRef)
    }

    /// Generates a diff for a file in the working directory using Git.
    ///
    /// This function constructs the appropriate git diff command based on the file's status and whether
    /// whitespace should be hidden in the diff output. It handles special cases for new or untracked files
    /// and submodules. After executing the git command, it parses the output for line endings warnings and
    /// builds the final diff object.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - file: A `WorkingDirectoryFileChange` object representing the file to diff.
    ///   - hideWhitespaceInDiff: A Boolean value indicating whether whitespace changes should be ignored in the diff.
    /// - Returns: An object conforming to the `IDiff` protocol that represents the generated diff.
    /// - Throws: An error if the git command fails or if there's an error building the diff.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = WorkingDirectoryFileChange(path: "file.txt", status: .modified)
    /// let diff = try getWorkingDirectoryDiff(directoryURL: directoryURL,
    ///                                        file: fileChange,
    ///                                        hideWhitespaceInDiff: true)
    /// ```
    func getWorkingDirectoryDiff(directoryURL: URL,
                                 file: WorkingDirectoryFileChange,
                                 hideWhitespaceInDiff: Bool = false) throws -> IDiff {
        var args = [
            "diff",
            "--no-ext-diff",
            "--patch-with-raw",
            "-z",
            "--no-color"
        ] + (hideWhitespaceInDiff ? ["-w"] : [])

        var successExitCodes: Set<Int> = [0]
        let isSubmodule = file.status?.submoduleStatus != nil

        // If the file is new or untracked, and it's not a submodule, use `--no-index`
        if !isSubmodule && (file.status?.kind == .new || file.status?.kind == .untracked) {
            args += ["--no-index", "--", "/dev/null", file.path]
            successExitCodes.insert(1) // Exit code 1 is also considered a success in this context
        } else if file.status?.kind == .renamed {
            args += ["--", file.path]
        } else {
            args += ["HEAD", "--", file.path]
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: successExitCodes))

        // Parse any potential line endings warning
        let lineEndingsChange = parseLineEndingsWarning(errorText: result.gitErrorDescription!)

        // Build the diff
        return try buildDiff(buffer: result.stdout,
                             directoryURL: directoryURL,
                             file: file,
                             oldestCommitish: "HEAD",
                             lineEndingChange: lineEndingsChange
        )
    }

    /// Creates an image diff object for a file between two commits in a repository.
    ///
    /// This function determines the current and previous state of an image file based on its change status.
    /// If the file is not marked as deleted, it retrieves the current image from the working directory.
    /// If the file is not new or untracked, it retrieves the previous image from the specified oldest commit.
    /// It then returns an `IImageDiff` object representing the difference between the two images.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - file: A `FileChange` object representing the file change to be diffed.
    ///   - oldestCommitish: A string representing the oldest commit to compare against.
    /// - Returns: An `IImageDiff` object representing the diff of the image.
    /// - Throws: An error if there is a problem retrieving the images for the diff.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = FileChange(path: "path/to/image.png", status: .modified)
    /// let imageDiff = try getImageDiff(directoryURL: directoryURL,
    ///                                  file: fileChange,
    ///                                  oldestCommitish: "d3adb33f")
    /// ```
    func getImageDiff(directoryURL: URL,
                      file: FileChange,
                      oldestCommitish: String) throws -> IImageDiff {
        var current: DiffImage?
        var previous: DiffImage?

        if file.status?.kind != .conflicted {
            if file.status?.kind != .deleted {
                current = try getWorkingDirectoryImage(directoryURL: directoryURL, file: file)
            }

            if file.status?.kind != .new && file.status?.kind != .untracked {
                previous = try getBlobImage(directoryURL: directoryURL,
                                            path: FileUtils().getOldPathOrDefault(file: file),
                                            commitish: "HEAD")
            }
        }

        if file.status?.kind != .deleted {
            current = try getBlobImage(directoryURL: directoryURL,
                                       path: file.path,
                                       commitish: oldestCommitish)
        }

        if file.status?.kind != .new && file.status?.kind != .untracked {
            previous = try getBlobImage(directoryURL: directoryURL,
                                        path: FileUtils().getOldPathOrDefault(file: file),
                                        commitish: "\(oldestCommitish)^")
        }

        return IImageDiff(kind: .image, previous: previous, current: current)
    }

    func convertDiff(directoryURL: URL,
                     file: FileChange,
                     diff: IRawDiff,
                     oldestCommitish: String,
                     lineEndingsChange: LineEndingsChange?) throws -> IDiff {
        let `extension` = (file.path as NSString).pathExtension.lowercased()

        if diff.isBinary {
            if !imageFileExtensions.contains(`extension`) {
                return IBinaryDiff()
            } else {
                return try getImageDiff(directoryURL: directoryURL,
                                        file: file,
                                        oldestCommitish: oldestCommitish)
            }
        }

        return ITextDiff(text: diff.contents,
                         hunks: diff.hunks,
                         lineEndingsChange: lineEndingsChange,
                         maxLineNumber: diff.maxLineNumber,
                         hasHiddenBidiChars: diff.hasHiddenBidiChars)
    }

    /// `git diff` will write out messages about the line ending changes it knows
    /// about to `stderr` - this rule here will catch this and also the to/from
    /// changes based on what the user has configured.
    private let lineEndingsChangeRegex = "', (CRLF|CR|LF) will be replaced by (CRLF|CR|LF) the .*"

    /// Parses a warning message about line ending changes and creates a `LineEndingsChange` object.
    ///
    /// This function uses a regular expression to search for a line endings change warning within the provided
    /// `errorText`. If a match is found, it extracts the 'from' and 'to' line ending types from the text and
    /// constructs a `LineEndingsChange` object with this information.
    ///
    /// - Parameter errorText: A string containing the error text that potentially includes a line endings \
    ///                        change warning.
    /// - Returns: An optional `LineEndingsChange` object if the warning is found; otherwise, `nil`.
    ///
    /// # Example:
    /// ```
    /// let warningText = "warning: LF will be replaced by CRLF in file.txt."
    /// if let lineEndingsChange = parseLineEndingsWarning(errorText: warningText) {
    ///     print("Line endings changed from \(lineEndingsChange.from) to \(lineEndingsChange.to)")
    /// }
    /// ```
    ///
    /// - Note: The function assumes that the `errorText` contains a warning about line ending changes \ 
    ///         in a standard format.
    ///
    ///   If no match is found, or if the `from` and `to` values can't be parsed, the function returns `nil`.
    ///   This function uses forced unwrapping after parsing line endings,
    ///   which could lead to runtime crashes if the parsing fails.
    func parseLineEndingsWarning(errorText: String) -> LineEndingsChange? {
        guard let regex = try? NSRegularExpression(pattern: lineEndingsChangeRegex, options: []) else {
            print("Failed to create regular expression for line endings change warning")
            return nil
        }

        let nsRange = NSRange(errorText.startIndex..<errorText.endIndex, in: errorText)
        if let match = regex.firstMatch(in: errorText, options: [], range: nsRange) {
            if let fromRange = Range(match.range(at: 1), in: errorText),
               let toRange = Range(match.range(at: 2), in: errorText) {
                let from = parseLineEndingText(text: String(errorText[fromRange]))
                let to = parseLineEndingText(text: String(errorText[toRange]))
                return LineEndingsChange(from: from!, to: to!)
            }
        }

        return nil
    }

    /// Parses the raw output of a diff command into an `IRawDiff` object.
    ///
    /// This function splits the given raw diff output on null (\0) characters, which are
    /// used as delimiters in the raw output format. It then constructs an `IRawDiff` object
    /// by parsing the last piece of the split output. If the output is invalid and cannot be
    /// parsed, it forces an unwrap which will crash if the output is not valid.
    ///
    /// - Parameter output: A string containing the raw output from a diff command.
    /// - Returns: An `IRawDiff` object representing the parsed diff.
    ///
    /// Example:
    /// ```
    /// let rawDiffOutput = "<raw-diff-output>"
    /// let diff = diffFromRawDiffOutput(output: rawDiffOutput)
    /// ```
    ///
    /// - Warning: If the raw diff output is invalid and does not contain any pieces after splitting,
    ///   this function will trigger a runtime error.
    func diffFromRawDiffOutput(output: String) -> IRawDiff {
        let pieces = output.split(separator: "\0", omittingEmptySubsequences: false)
        let parser = DiffParser()
        return parser.parse(text: forceUnwrap("Invalid diff output", pieces.last.map(String.init)))
    }

    /// Constructs a diff object for a submodule change within a repository.
    ///
    /// This function analyzes a buffer containing the output of a diff operation,
    /// specifically looking for changes in submodules. It extracts the old and new SHA
    /// references for the submodule and constructs an `ISubmoduleDiff` object with this
    /// information along with the kind of change and the submodule's URL.
    ///
    /// - Parameters:
    ///   - buffer: A string containing the output from a diff command.
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - file: A `FileChange` object representing the submodule file change.
    ///   - status: A `SubmoduleStatus` object encapsulating the status of the submodule.
    /// - Returns: An object conforming to the `IDiff` protocol representing the submodule diff.
    /// - Throws: An error if the submodule URL cannot be retrieved or if regex operations fail.
    ///
    /// Example:
    /// ```
    /// let buffer = "<diff output>"
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = FileChange(path: "path/to/submodule", status: .modified)
    /// let submoduleStatus = SubmoduleStatus(commitChanged: true)
    /// let submoduleDiff = try buildSubmoduleDiff(buffer: buffer,
    ///                                            directoryURL: directoryURL,
    ///                                            file: fileChange,
    ///                                            status: submoduleStatus)
    /// ```
    func buildSubmoduleDiff(buffer: String,
                            directoryURL: URL,
                            file: FileChange,
                            status: SubmoduleStatus) throws -> IDiff {
        let path = file.path
        let fullPath = directoryURL.appendingPathComponent(path).path
        let url = try Config().getConfigValue(directoryURL: directoryURL, name: "submodule.\(path).url")

        var oldSHA: String?
        var newSHA: String?

        if status.commitChanged ||
            file.status?.kind == .new ||
            file.status?.kind == .deleted {
            let lines = buffer.split(separator: "\n")
            let baseRegex = "Subproject commit ([^-]+)(-dirty)?$"
            guard let oldSHARegex = try? NSRegularExpression(pattern: "-" + baseRegex),
                  let newSHARegex = try? NSRegularExpression(pattern: "\\+" + baseRegex) else {
                throw NSError(
                    domain: "com.auroraeditor.versioncontrolkit.diff",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to create regular expression for submodule diff"
                    ]
                )
            }

            let lineMatch = { (regex: NSRegularExpression) -> String? in
                for line in lines {
                    if let match = regex.firstMatch(
                        in: String(line),
                        range: NSRange(location: 0, length: line.utf16.count)
                    ),
                    let range = Range(match.range(at: 1), in: String(line)) {
                        return String(line[range])
                    }
                }

                return nil
            }

            oldSHA = lineMatch(oldSHARegex)
            newSHA = lineMatch(newSHARegex)
        }

        return ISubmoduleDiff(kind: .submodule,
                              fullPath: fullPath,
                              path: path,
                              url: url,
                              status: status,
                              oldSHA: oldSHA,
                              newSHA: newSHA)
    }

    func buildDiff(buffer: String,
                   directoryURL: URL,
                   file: FileChange,
                   oldestCommitish: String,
                   lineEndingChange: LineEndingsChange?) throws -> IDiff {
        if file.status?.submoduleStatus != nil {
            return try buildSubmoduleDiff(buffer: buffer,
                                          directoryURL: directoryURL,
                                          file: file,
                                          status: (file.status?.submoduleStatus)!)
        }

        if !isValidBuffer(buffer) {
            // the buffer's diff is too large to be renderable in the UI
            return Diff(kind: .unrenderable)
        }

        let diff = diffFromRawDiffOutput(output: buffer)

        if isBufferTooLarge(buffer) || isDiffToLarge(diff: diff) {
            // we don't want to render by default
            // but we keep it as an option by
            // passing in text and hunks
            let largeTextDiff = ILargeTextDiff(
                text: diff.contents,
                hunks: diff.hunks,
                lineEndingsChange: lineEndingChange,
                maxLineNumber: diff.maxLineNumber,
                hasHiddenBidiChars: diff.hasHiddenBidiChars
            )

            return largeTextDiff
        }

        return try convertDiff(directoryURL: directoryURL,
                               file: file,
                               diff: diff,
                               oldestCommitish: oldestCommitish,
                               lineEndingsChange: lineEndingChange)
    }

    /// Retrieves the image data for a file at a specified commit and constructs a `DiffImage` object.
    ///
    /// This function fetches the blob contents from a git repository at the given commitish
    /// for the file specified by the path. It encodes the blob data to a base64 string, determines
    /// the file's media type based on its extension, and includes this in the returned `DiffImage` object.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - path: The path to the file within the git repository.
    ///   - commitish: The name of the commit/branch/tag from which to fetch the blob.
    /// - Returns: A `DiffImage` object containing the base64 encoded contents of the file, \
    ///            its media type, and size in bytes.
    /// - Throws: An error if the blob contents cannot be retrieved or encoded.
    ///
    /// Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let diffImage = try getBlobImage(directoryURL: directoryURL,
    ///                                  path: "path/to/image.png",
    ///                                  commitish: "main")
    /// ```
    func getBlobImage(directoryURL: URL,
                      path: String,
                      commitish: String) throws -> DiffImage {
        let data = try Blob().getBlobContents(directoryURL: directoryURL,
                                              commitish: commitish,
                                              path: path)
        let base64Content = data.base64EncodedString()
        let fileExtension = URL(fileURLWithPath: path).pathExtension

        let mediaType = MediaDiff().getMediaType(extension: fileExtension)

        return DiffImage(contents: base64Content,
                         mediaType: mediaType,
                         bytes: data.count)
    }

    /// Creates a `DiffImage` object representing the image of a file in the working directory.
    ///
    /// This function reads the data for a specified file located in the working directory and encodes it
    /// into a base64 string. It also determines the media type of the file based on its extension and
    /// includes this information, along with the size in bytes, in the returned `DiffImage` object.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the file resides.
    ///   - file: A `FileChange` object representing the file to be processed.
    /// - Returns: A `DiffImage` object containing the base64 encoded contents of the file, \
    ///            its media type, and size in bytes.
    /// - Throws: An error if the data for the file cannot be read.
    ///
    /// - Note: The media type is determined by a separate function `getMediaType`\
    ///         which should handle various file extensions appropriately.
    ///
    /// Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/directory")
    /// let fileChange = FileChange(path: "image.png", changeType: .modified)
    /// let diffImage = try getWorkingDirectoryImage(directoryURL: directoryURL, file: fileChange)
    /// ```
    func getWorkingDirectoryImage(directoryURL: URL,
                                  file: FileChange) throws -> DiffImage {
        let fileURL = directoryURL.appendingPathComponent(file.path)
        let fileData = try Data(contentsOf: fileURL)

        let mediaType = MediaDiff().getMediaType(extension: fileURL.pathExtension)

        return DiffImage(contents: fileData.base64EncodedString(),
                         mediaType: mediaType,
                         bytes: fileData.count)
    }

    /// Retrieves a list of paths to binary files in a given directory and Git reference.
    ///
    /// The function utilizes the `git diff` command with `--numstat` and `-z` options to obtain
    /// the list of binary files that changed. It then filters the output using a regular expression
    /// to extract the binary file paths.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory to search for binary files.
    ///   - ref: The Git reference, such as a branch or commit hash, to compare changes against.
    /// - Returns: An array of strings representing the paths to binary files.
    /// - Throws: An error if the Git command fails or the regular expression is invalid.
    ///
    /// - Note: The `git diff --numstat -z` command is used to generate a machine-parsable list of changed files,
    ///   with `-z` terminating lines with a NUL character for binary safety.
    ///
    /// Example:
    /// ```
    /// let binaryPaths = try getBinaryPaths(directoryURL: URL(fileURLWithPath: "/path/to/repo"), ref: "HEAD")
    /// ```
    func getBinaryPaths(directoryURL: URL,
                        ref: String) throws -> [String] {
        let args = ["diff",
                    "--numstat",
                    "-z",
                    ref]

        let output = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        guard let binaryListRegex = try? NSRegularExpression(pattern: binaryListRegex, options: []) else {
            throw NSError(
                domain: "com.auroraeditor.versioncontrolkit.diff",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create regular expression for binary file list"
                ]
            )
        }

        let nsRange = NSRange(output.stdout.startIndex..<output.stdout.endIndex, in: output.stdout)
        let matches = binaryListRegex.matches(in: output.stdout, options: [], range: nsRange)

        let binaryPaths = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: output.stdout) else { return nil }
            return String(output.stdout[range])
        }

        return binaryPaths
    }
}

func forceUnwrap<T>(_ message: String, _ optional: T?) -> T {
    guard let value = optional else {
        fatalError(message)
    }
    return value
}

enum DiffErrors: Error {
    case noCommits(String)
}

// swiftlint:disable:this file_length
