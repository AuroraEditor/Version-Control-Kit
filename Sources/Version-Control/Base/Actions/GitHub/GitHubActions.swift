//
//  GitHubActions.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/25.
//

import Foundation
import AppKit

public enum GitHubViewType: String {
    case tree = "tree"
    case compare = "compare"
}

public struct GitHubActions {

    internal func getBranchName(directoryURL: URL) throws -> String {
        return try Branch().getCurrentBranch(directoryURL: directoryURL)
    }

    internal func getCurrentRepositoryGitHubURL(directoryURL: URL) throws -> String {
        let remoteUrls: [GitRemote] = try Remote().getRemotes(directoryURL: directoryURL)

        for remote in remoteUrls {
            if remote.url.contains("github.com") {
                return remote.url
            }
        }
        return ""
    }

    /// Open a specific branch of a GitHub repository in a web browser.
    ///
    /// This function constructs the URL for a specific branch of a GitHub repository based on the provided parameters and opens it in the default web browser.
    ///
    /// - Parameters:
    ///   - viewType: The type of view to open on GitHub (e.g., code, commits, pulls).
    ///   - directoryURL: The local directory URL of the Git repository.
    ///
    /// - Throws: An error if there's an issue with constructing the URL or opening it in the web browser.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let viewType = GitHubViewType.commits
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///       try openBranchOnGitHub(viewType: viewType, directoryURL: directoryURL)
    ///   } catch {
    ///       print("Error: Unable to open the GitHub branch.")
    ///   }
    public func openBranchOnGitHub(viewType: GitHubViewType,
                                   directoryURL: URL) throws {
        let htmlURL = try getCurrentRepositoryGitHubURL(directoryURL: directoryURL)
        let branchName = try getBranchName(directoryURL: directoryURL)

        let urlEncodedBranchName = branchName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        guard let encodedBranchName = urlEncodedBranchName else {
            return
        }

        let url = URL(string: "\(htmlURL)/\(viewType)/\(encodedBranchName)")

        NSWorkspace.shared.open(url!)
    }

    /// Open the GitHub issue creation page for the current repository in a web browser.
    ///
    /// This function constructs the URL for creating a new issue in the current repository on GitHub and opens it in the default web browser.
    ///
    /// - Parameter directoryURL: The local directory URL of the Git repository.
    ///
    /// - Throws: An error if there's an issue with constructing the URL or opening it in the web browser.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///       try openIssueCreationOnGitHub(directoryURL: directoryURL)
    ///   } catch {
    ///       print("Error: Unable to open the GitHub issue creation page.")
    ///   }
    public func openIssueCreationOnGitHub(directoryURL: URL) throws {
        let repositoryURL = try getCurrentRepositoryGitHubURL(directoryURL: directoryURL)

        let url = URL(string: "\(repositoryURL)/issues/new/choose")

        NSWorkspace.shared.open(url!)
    }
}
