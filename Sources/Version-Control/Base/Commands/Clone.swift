//
//  Clone.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Clone {

    public init() {}

    /// Clones a repository from a given url into to the specified path.
    ///
    /// @param url - The remote repository URL to clone from
    ///
    /// @param path - The destination path for the cloned repository. If the
    ///            path does not exist it will be created. Cloning into an
    ///            existing directory is only allowed if the directory is
    ///            empty.
    ///
    /// @param options  - Options specific to the clone operation, see the
    ///               documentation for CloneOptions for more details.
    ///
    /// @param progressCallback - An optional function which will be invoked
    ///                     with information about the current progress
    ///                     of the clone operation. When provided this enables
    ///                     the '--progress' command line flag for
    ///                     'git clone'.
    typealias CloneProgressCallback = (CloneProgress) -> Void

    let steps: [ProgressStep] = [
        ProgressStep(title: "remote: Compressing objects", weight: 0.1),
        ProgressStep(title: "Receiving objects", weight: 0.6),
        ProgressStep(title: "Resolving deltas", weight: 0.1),
        ProgressStep(title: "Checking out files", weight: 0.2)
    ]

    func clone(directoryURL: URL,
               path: String,
               options: CloneOptions,
               progressCallback: ((ICloneProgress) -> Void)? = nil) async throws {
//        let env = try await envForRemoteOperation(options.account, url)
        let defaultBranch = options.defaultBranch ?? (DefaultBranch().getDefaultBranch())

        var args = gitNetworkArguments + ["-c", "init.defaultBranch=\(defaultBranch)", "clone", "--recursive"]
        var gitOptions: IGitExecutionOptions = IGitExecutionOptions()

        if let progress = progressCallback {
            args.append("--progress")

            let title = "Cloning into \(path)"
            let kind = "clone"

            gitOptions = try FromProcess().executionOptionsWithProgress(
                options: gitOptions,
                parser: GitProgressParser(steps: steps),
                progressCallback: { progressInfo in
                    var description: String = ""

                    if let gitProgress = progressInfo as? IGitProgress, progressInfo.kind == "progress" {
                        description = gitProgress.details.text
                    } else if let gitOutput = progressInfo as? IGitOutput {
                        description = gitOutput.text
                    }

                    let value = progressInfo.percent

                    progressCallback?(CloneProgress(kind: kind, value: value, title: title, description: description))
                }
            )

            progressCallback?(CloneProgress(kind: kind, value: 0, title: title))
        }

        if let branch = options.branch {
            args += ["-b", branch]
        }

        args += ["--", directoryURL.relativePath.escapedWhiteSpaces(), path]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function,
                           options: gitOptions)
    }
}
