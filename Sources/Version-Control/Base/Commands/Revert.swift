//
//  Revert.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitRevert {
    /// Creates a new commit that reverts the changes of a previous commit
    ///
    /// @param sha - The SHA of the commit to be reverted
    func revertCommit(directoryURL: URL,
                      commit: Commit,
                      progressCallback: ((RevertProgress) -> Void)?
    ) throws {
        var args = gitNetworkArguments + ["revert"]
        if commit.parentSHAs.count > 1 {
            args += ["-m", "1"]
        }

        args.append(commit.sha)

        var opts: IGitExecutionOptions?
        if let progressCallback = progressCallback {
            opts = try FromProcess().executionOptionsWithProgress(
                options: IGitExecutionOptions(trackLFSProgress: true),
                parser: GitProgressParser(steps: [ProgressStep(title: "", weight: 0)]),
                progressCallback: { progress in
                    var description: String = ""
                    var title: String = ""

                    if let gitProgress = progress as? IGitProgress, progress.kind == "progress" {
                        description = gitProgress.details.text
                        title = gitProgress.details.title
                    } else if let gitOutput = progress as? IGitOutput {
                        description = gitOutput.text
                        title = ""
                    }

                    let value = progress.percent

                    progressCallback(RevertProgress(kind: "revert",
                                                    value: value,
                                                    title: title,
                                                    description: description))
                }
            )
        }

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function,
                           options: opts)
    }
}
