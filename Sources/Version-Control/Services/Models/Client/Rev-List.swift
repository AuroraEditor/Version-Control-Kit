//
//  Rev-List.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/17.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

/// Convert two references into Git's range syntax.
///
/// Git's range syntax represents the set of commits that are reachable from the `to` reference but excludes those that are reachable from the `from` reference. This syntax is not inclusive of the `from` reference itself; it only includes commits up to the `to` reference.
///
/// - Parameters:
///   - from: The source reference or commit SHA.
///   - to: The target reference or commit SHA.
///
/// - Returns:
///   - A string representing the range between the two references in Git syntax.
///
/// - Example:
///   ```swift
///   let sourceRef = "main" // Replace with the source reference
///   let targetRef = "feature-branch" // Replace with the target reference
///
///   let range = revRange(from: sourceRef, to: targetRef)
///   print("Range: \(range)")
///   ```
///
/// - Note:
///   The Git range syntax is used to represent the set of commits that are reachable from the `to` 
///   reference but excludes those that are reachable from the `from` reference. \
///   It does not include the commit specified by the `from` reference.
///
/// - Warning:
///   Ensure that the `from` and `to` parameters represent valid references or commit SHA values 
///   to avoid syntax errors when using the resulting string in Git commands.
///
/// - SeeAlso:
///   [Git Range](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefrangea)
private func revRange(from: String, to: String) -> String {
    return "\(from)..\(to)"
}

/// Convert two references into Git's inclusive range syntax.
///
/// Git's inclusive range syntax represents the set of commits that are reachable from the `to` reference but excludes those that are reachable from the `from` reference. Unlike `revRange`, this syntax includes the `from` reference itself.
///
/// - Parameters:
///   - from: The source reference or commit SHA.
///   - to: The target reference or commit SHA.
///
/// - Returns:
///   - A string representing the inclusive range between the two references in Git syntax.
///
/// - Example:
///   ```swift
///   let sourceRef = "main" // Replace with the source reference
///   let targetRef = "feature-branch" // Replace with the target reference
///
///   let inclusiveRange = revRangeInclusive(from: sourceRef, to: targetRef)
///   print("Inclusive Range: \(inclusiveRange)")
///   ```
///
/// - Note:
///   The Git inclusive range syntax is used to represent the set of commits that are reachable from the `to` reference but excludes those that are reachable from the `from` reference. It includes the commit specified by the `from` reference.
///
/// - Warning:
///   Ensure that the `from` and `to` parameters represent valid references or commit SHA values 
///   to avoid syntax errors when using the resulting string in Git commands.
///
/// - SeeAlso:
///   [Git Inclusive Range](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefinclusiverangea)
private func revRangeInclusive(from: String, to: String) -> String {
    return "\(from)^...\(to)"
}

/// Convert two references into Git's symmetric difference syntax.
///
/// Git's symmetric difference syntax represents the set of commits that are reachable from either
/// the `from` reference or the `to` reference but not from both. This function takes two parameters,
/// `from` and `to`, which can be specified as commit SHA values, reference names, 
/// or an empty string to represent the HEAD reference.
///
/// - Parameters:
///   - from: The source reference or commit SHA.
///   - to: The target reference or commit SHA.
///
/// - Returns:
///   - A string representing the symmetric difference between the two references in Git syntax.
///
/// - Example:
///   ```swift
///   let sourceRef = "main" // Replace with the source reference
///   let targetRef = "feature-branch" // Replace with the target reference
///
///   let symmetricDiff = revSymmetricDifference(from: sourceRef, to: targetRef)
///   print("Symmetric Difference: \(symmetricDiff)")
///   ```
///
/// - Note:
///   The Git symmetric difference syntax is used to represent the set of commits that are 
///   reachable from either the `from` reference or the `to` reference but not from both. \
///   It is commonly used in Git operations such as comparing branches or 
///   finding the differences between two references.
///
/// - Warning:
///   Ensure that the `from` and `to` parameters represent valid references or commit SHA values to
///   avoid syntax errors when using the resulting string in Git commands.
///
/// - SeeAlso:
///   https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefsymmetricdiffa
private func revSymmetricDifference(from: String, to: String) -> String {
    return "\(from)...\(to)"
}

/// Calculate the number of commits that a given commit range is ahead of and behind.
///
/// This function calculates the number of commits that a specified commit range is ahead of and behind in
/// a Git repository located at the specified `directoryURL`. \
/// The commit range is represented by the `range` parameter, and the result is returned as 
/// an `AheadBehind` object containing the counts of commits ahead and behind.
///
/// - Parameters:
///   - directoryURL: The URL of the directory containing the Git repository.
///   - range: A string specifying the commit range to analyze, typically in the form of `<refA>..<refB>`.
///
/// - Returns:
///   - An `AheadBehind` object representing the number of commits ahead and behind in the specified commit range.
///   - `nil` if the commit range is invalid, one of the references does not exist, \
///     or an error occurs during the calculation.
///
/// - Throws:
///   - An error of type `Error` if any issues occur during the calculation process.
///
/// - Example:
///   ```swift
///   let repositoryPath = "/path/to/repo" // Replace with the path to the Git repository
///   let commitRange = "main..feature-branch" // Replace with the desired commit range
///
///   do {
///       if let aheadBehind = try getAheadBehind(directoryURL: repositoryPath, range: commitRange) {
///           print("Commits Ahead: \(aheadBehind.ahead)")
///           print("Commits Behind: \(aheadBehind.behind)")
///       } else {
///           print("Invalid commit range or error occurred.")
///       }
///   } catch {
///       print("Error calculating ahead/behind commits: \(error.localizedDescription)")
///   }
///   ```
///
/// - Note:
///   This function uses the `git rev-list` command with the `--left-right` and `--count` options
///   to calculate the number of commits ahead of and behind a specified commit range. \
///   The result is returned as an `AheadBehind` object.
///
/// - Warning:
///   Be cautious when using this function, as an invalid commit range or non-existent references
///   may result in errors, and it assumes that the Git executable is available and accessible in the system's PATH.
public func getAheadBehind(directoryURL: URL,
                           range: String) throws -> IAheadBehind? {
    // `--left-right` annotates the list of commits in the range with which side
    // they're coming from. When used with `--count`, it tells us how many
    // commits we have from the two different sides of the range.
    let args = ["rev-list", "--left-right", "--count", range, "--"]

    let result = try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)"
    )

    // This means one of the refs (most likely the upstream branch) no longer
    // exists. In that case, we can't be ahead/behind at all.
    if result.contains(GitError.badRevision.rawValue) {
        return nil
    }

    let pieces = result.split(separator: "\t")

    if pieces.count != 2 {
        return nil
    }

    let ahead = Int(pieces[0], radix: 10)
    if ahead != nil {
        return nil
    }

    let behind = Int(pieces[1], radix: 10)
    if behind != nil {
        return nil
    }

    return IAheadBehind(ahead: ahead!, behind: behind!)
}

/// Retrieve the number of commits ahead and behind between a local branch and its upstream branch.
///
/// This function calculates the number of commits that a local branch is ahead and behind its
/// corresponding upstream branch. \
/// It provides information about how the local branch differs from its upstream branch, 
/// taking into account merge bases and merge commits.
///
/// - Parameters:
///   - directoryURL: The URL of the Git repository directory.
///   - branch: The local branch for which you want to determine the ahead and behind commits.
///
/// - Returns: An `IAheadBehind` object that encapsulates the number of commits ahead and behind the upstream branch. \
///            If the branch type is remote or no upstream branch is set, `nil` is returned.
///
/// - Example:
///   ```swift
///   let repositoryDirectory = URL(fileURLWithPath: "/path/to/git/repo")
///   let branch = Branch(name: "my-feature-branch", type: .local, upstream: "origin/my-feature-branch")
///
///   do {
///       if let aheadBehind = try getBranchAheadBehind(directoryURL: repositoryDirectory, branch: branch) {
///           print("Branch is \(aheadBehind.ahead) commits ahead and \(aheadBehind.behind)
///                  commits behind its upstream branch.")
///       } else {
///           print("No upstream branch set or branch type is remote.")
///       }
///   } catch {
///       print("Error occurred while calculating ahead and behind commits: \(error)")
///   }
///   ```
///
/// - Note:
///   This function is useful for tracking the differences between a local branch and its upstream branch. \
///   It calculates the commits that have been added or removed from the local branch compared to its upstream branch.
///
/// - Warning:
///   Ensure that the branch provided as a parameter is a valid local branch, and it has an upstream branch set. \
///   Otherwise, the function will return `nil`.
///
/// - Returns: An `IAheadBehind` object representing the number of commits ahead and behind the upstream branch, \ 
///            or `nil` if the branch type is remote or no upstream branch is set.
func getBranchAheadBehind(directoryURL: URL,
                          branch: GitBranch) async throws -> IAheadBehind? {
    if branch.type == .remote {
        return nil
    }

    guard let upstream = branch.upstream else {
        return nil
    }

    // NB: The three-dot form means we'll go all the way back to the merge base
    // of the branch and its upstream. Practically, this is important for seeing
    // "through" merges.
    let range = revSymmetricDifference(from: branch.name, to: upstream)
    return try getAheadBehind(directoryURL: directoryURL, range: range)
}

/// Retrieve a list of commits between two specified commit references in a Git repository.
///
/// This function retrieves a list of commits between the specified `baseBranchSha` and `targetBranchSha` \
/// in a Git repository located at the specified `directoryURL`.
/// The commits are ordered in the sequence they will be applied to the `baseBranchSha`, \
/// emulating the behavior of `git rebase`.
///
/// - Parameters:
///   - directoryURL: The URL of the directory containing the Git repository.
///   - baseBranchSha: The commit SHA of the base branch, representing the starting point.
///   - targetBranchSha: The commit SHA of the target branch, representing the ending point (not included).
///
/// - Returns:
///   - An array of `CommitOneLine` objects representing commits between the `baseBranchSha` (inclusive) \
///     and `targetBranchSha` (exclusive). Each `CommitOneLine` object contains a commit SHA and a commit summary.
///   - `nil` if the rebase is not possible to perform due to a missing commit ID or \
///     if an error occurs during the retrieval.
///
/// - Throws:
///   - An error of type `Error` if any issues occur during the retrieval process.
///
/// - Example:
///   ```swift
///   let repositoryPath = "/path/to/repo" // Replace with the path to the Git repository
///   let baseBranchCommitSHA = "abcdef123456" // Replace with the SHA of the base branch commit
///   let targetBranchCommitSHA = "7890abcd5678" // Replace with the SHA of the target branch commit
///
///   do {
///       if let commits = try getCommitsBetweenCommits(
///           directoryURL: repositoryPath,
///           baseBranchSha: baseBranchCommitSHA,
///           targetBranchSha: targetBranchCommitSHA
///       ) {
///           for commit in commits {
///               print("Commit SHA: \(commit.sha)")
///               print("Commit Summary: \(commit.summary)")
///           }
///       } else {
///           print("Rebase not possible due to missing commit ID or error occurred.")
///       }
///   } catch {
///       print("Error retrieving commits: \(error.localizedDescription)")
///   }
///   ```
///
/// - Note:
///   This function uses the `git rev-range` command to retrieve a list of commits between two commit references. \
///   The commits are represented as `CommitOneLine` objects, 
///   where each object contains a commit SHA and a commit summary.
///
/// - Warning:
///   Be cautious when using this function, as missing commit IDs or invalid commit references may result in errors,
///   and it assumes that the Git executable is available and accessible in the system's PATH.
public func getCommitsBetweenCommits(directoryURL: URL,
                                     baseBranchSha: String,
                                     targetBranchSha: String) throws -> [CommitOneLine]? {
    let range = revRange(from: baseBranchSha, to: targetBranchSha)
    return try getCommitsInRange(directoryURL: directoryURL, range: range)
}

/// Retrieve a list of commits within the specified commit range in a Git repository.
///
/// This function retrieves a list of commits within the specified `range` in a Git repository \
/// located at the specified `directoryURL`. 
/// The `range` parameter should represent a commit range, such as a branch or commit range expression.
///
/// - Parameters:
///   - directoryURL: The URL of the directory containing the Git repository.
///   - range: The commit range expression used to filter commits.
///
/// - Returns:
///   - An array of `CommitOneLine` objects representing commits within the specified range. \
///     Each `CommitOneLine` object contains a commit SHA and a commit summary.
///   - `nil` if the specified `range` is invalid or if an error occurs during the retrieval.
///
/// - Throws:
///   - An error of type `Error` if any issues occur during the retrieval process.
///
/// - Example:
///   ```swift
///   let repositoryPath = "/path/to/repo" // Replace with the path to the Git repository
///   let commitRange = "main..feature/branch" // Replace with the desired commit range
///
///   do {
///       if let commits = try getCommitsInRange(directoryURL: repositoryPath, range: commitRange) {
///           for commit in commits {
///               print("Commit SHA: \(commit.sha)")
///               print("Commit Summary: \(commit.summary)")
///           }
///       } else {
///           print("Invalid commit range or error occurred.")
///       }
///   } catch {
///       print("Error retrieving commits: \(error.localizedDescription)")
///   }
///   ```
///
/// - Note:
///   This function uses the `git rev-list` command to retrieve a list of commits within the specified range. 
///   The commits are represented as `CommitOneLine` objects, \
///   where each object contains a commit SHA and a commit summary.
///
/// - Warning:
///   Be cautious when using this function, as invalid commit range expressions may result in errors, \
///   and it assumes that the Git executable \
///   is available and accessible in the system's PATH.
public func getCommitsInRange(directoryURL: URL,
                              range: String) throws -> [CommitOneLine]? {

    let args = [
        "rev-list",
        range,
        "--reverse",
        // the combination of these two arguments means each line of the stdout
        // will contain the full commit sha and a commit summary
        "--oneline",
        "--no-abbrev-commit",
        "--"
    ]

    let result = try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)"
    )

    if result.contains(GitError.badRevision.rawValue) {
        return nil
    }

    var commits: [CommitOneLine] = []

    if result.count == 3 {
        let sha = result.substring(1)
        let summary = result.substring(2)

        commits.append(CommitOneLine(sha: sha, summary: summary))
    }

    return commits
}
