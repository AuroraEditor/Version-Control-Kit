//
//  Squash.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitSquash {

    /// Squashes provided commits by calling interactive rebase.
    ///
    /// Goal is to replay the commits in order from oldest to newest to reduce
    /// conflicts with toSquash commits placed in the log at the location of the
    /// squashOnto commit.
    ///
    /// Example: A user's history from oldest to newest is A, B, C, D, E and they
    /// want to squash A and E (toSquash) onto C. Our goal:  B, A-C-E, D. Thus,
    /// maintaining that A came before C and E came after C, placed in history at the
    /// the squashOnto of C.
    ///
    /// Also means if the last 2 commits in history are A, B, whether user squashes A
    /// onto B or B onto A. It will always perform based on log history, thus, B onto
    /// A.
    func squash(directoryURL: URL,
                toSquash: [Commit],
                squashOnto: Commit,
                lastRetainedCommitRef: String?,
                commitMessage: String,
                progressCallback: ((MultiCommitOperationProgress) -> Void)? = nil) async throws -> RebaseResult {
        var messagePath: String?
        var todoPath: String?
        var result: RebaseResult = .error

        do {
            guard toSquash.count > 0 else {
                throw NSError(domain: "Squash Error",
                              code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No commits provided to squash."])
            }

            let toSquashShas = Set(toSquash.map { $0.sha })
            guard !toSquashShas.contains(squashOnto.sha) else {
                throw NSError(domain: "Squash Error",
                              code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "The commits to squash cannot contain the commit to squash onto."])
            }

            let commits = try GitLog().getCommits(directoryURL: directoryURL,
                                                  revisionRange: lastRetainedCommitRef == nil ? nil : "\(lastRetainedCommitRef!)..HEAD",
                                                  limit: nil,
                                                  skip: nil)

            guard !commits.isEmpty else {
                throw NSError(domain: "Squash Error",
                              code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Could not find commits in log for last retained commit ref."])
            }

            todoPath = try await FileUtils().writeToTempFile(content: "", tempFileName: "squashTodo")

            // Logic for building the todoPath content goes here

            if !commitMessage.trimmingCharacters(in: .whitespaces).isEmpty {
                messagePath = try await FileUtils().writeToTempFile(content: commitMessage, tempFileName: "squashCommitMessage")
            }

            let gitEditor = messagePath != nil ? "cat \"\(messagePath!)\" >" : nil

            result = try Rebase().rebaseInteractive(
                directoryURL: directoryURL,
                pathOfGeneratedTodo: todoPath!,
                lastRetainedCommitRef: lastRetainedCommitRef,
                action: "Squash",
                gitEditor: gitEditor ?? ":",
                progressCallback: progressCallback,
                commits: toSquash + [squashOnto]
            )
        } catch {
            print("Error occurred: \(error)")
            return .error
        }

        return result
    }
}
