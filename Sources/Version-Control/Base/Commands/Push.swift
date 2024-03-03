//
//  Push.swift
//
//
//  Created by Nanashi Li on 2023/11/01.
//

import Foundation

public struct PushOptions {
    /**
     * Force-push the branch without losing changes in the remote that
     * haven't been fetched.
     *
     * See https://git-scm.com/docs/git-push#Documentation/git-push.txt---no-force-with-lease
     */
    let forceWithLease: Bool = false
}

public struct Push {

    public init() {}

    public func push( // swiftlint:disable:this function_parameter_count
        directoryURL: URL,
        remote: IRemote,
        localBranch: String,
        remoteBranch: String?,
        tagsToPush: [String]?,
        options: PushOptions,
        progressCallback: ((IPushProgress) -> Void)? = nil
    ) throws {
        var args = gitNetworkArguments + [
            "push",
            remote.name,
            remoteBranch != nil ? "\(localBranch):\(remoteBranch!)" : localBranch
        ]

        if let tags = tagsToPush {
            args += tags
        }

        if remoteBranch == nil {
            args.append("--set-upstream")
        } else if options.forceWithLease {
            args.append("--force-with-lease")
        }

        // TODO: Add progress support

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        if result.gitErrorDescription != nil {
            throw GitErrorParser(result: result,
                                 args: args)
        }
    }
}
