//
//  Pull.swift
//
//
//  Created by Nanashi Li on 2023/11/01.
//

import Foundation

public struct GitPull {

    public init() {}

    let pullOperationSteps = [
        ProgressStep(title: "remote: Compressing objects", weight: 0.1),
        ProgressStep(title: "Receiving objects", weight: 0.7),
        ProgressStep(title: "Resolving deltas", weight: 0.15),
        ProgressStep(title: "Checking out files", weight: 0.15)
    ]

    func getPullArgs(directoryURL: URL,
                     remote: String,
                     account: IGitAccount?,
                     progressCallback: ((IPullProgress) -> Void)? = nil) throws -> [String] {
        let divergentPathArgs = getDefaultPullDivergentBranchArguments(directoryURL: directoryURL)

        var args = gitNetworkArguments + gitRebaseArguments + ["pull"] + divergentPathArgs

        args.append("--recurse-submodules")

        if progressCallback != nil {
            args.append("--progress")
        }

        args.append(remote)

        return args
    }

    func pull(directoryURL: URL,
              account: IGitAccount?,
              remote: IRemote,
              progressCallback: ((IPullProgress) -> Void)? = nil) throws {
        var options = IGitExecutionOptions(env: [:])

        if let progress = progressCallback {
            let title = "Pulling \(remote.name)"
            let kind = "pull"

            options = try FromProcess().executionOptionsWithProgress(
                options: options,
                parser: GitProgressParser(steps: pullOperationSteps),
                progressCallback: { progressInfo in
                    var description: String = ""

                    if let gitProgress = progressInfo as? IGitProgress, progressInfo.kind == "progress" {
                        description = gitProgress.details.text
                    } else if let gitOutput = progressInfo as? IGitOutput {
                        description = gitOutput.text
                    }

                    let value = progressInfo.percent

                    progress(PullProgress(kind: kind,
                                          remote: remote.name,
                                          value: value,
                                          title: title,
                                          description: description))
                }
            )

            // Initial progress
            progress(PullProgress(kind: kind,
                                  remote: remote.name,
                                  value: 0,
                                  title: title))
        }

        let args = try getPullArgs(directoryURL: directoryURL,
                                   remote: remote.name,
                                   account: account,
                                   progressCallback: progressCallback)

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        if let gitErrorDescription = result.gitErrorDescription {
            throw GitErrorParser(result: result,
                                 args: args)
        }
    }

    func getDefaultPullDivergentBranchArguments(directoryURL: URL) -> [String] {
        do {
            let pullFF = try Config().getConfigValue(directoryURL: directoryURL, name: "pull.ff")
            return (pullFF != nil) ? [] : ["--ff"]
        } catch {
            print("Couldn't read 'pull.ff' config", error)
        }

        // If there is a failure in checking the config, we still want to use any
        // config and not overwrite the user's set config behavior. This will show the
        // git error if no config is set.
        return []
    }

}
