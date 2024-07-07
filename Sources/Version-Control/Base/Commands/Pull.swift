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

    /// Generate arguments for the Git pull command.
    ///
    /// This function generates the arguments needed for the Git pull command, including handling
    /// divergent branch arguments, recurse submodules, and progress options.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - remote: The name of the remote repository to pull from.
    ///   - account: An optional `IGitAccount` object for authentication.
    ///   - progressCallback: An optional callback function to handle progress updates.
    ///
    /// - Returns: An array of strings representing the arguments for the Git pull command.
    ///
    /// - Throws: An error if the arguments cannot be generated.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let remote = "origin"
    ///   let args = try getPullArgs(directoryURL: directoryURL, remote: remote, account: nil, progressCallback: nil)
    ///   print("Pull args: \(args)")
    ///   ```
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

    /// Perform a Git pull operation.
    ///
    /// This function performs a Git pull operation for the specified remote repository. It supports progress
    /// updates through a callback function.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - account: An optional `IGitAccount` object for authentication.
    ///   - remote: An `IRemote` object representing the remote repository to pull from.
    ///   - progressCallback: An optional callback function to handle progress updates.
    ///
    /// - Throws: An error if the pull operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let remote = IRemote(name: "origin")
    ///
    ///   do {
    ///       try pull(directoryURL: directoryURL, account: nil, remote: remote, progressCallback: { progress in
    ///           print("Pull progress: \(progress.value)% - \(progress.description)")
    ///       })
    ///   } catch {
    ///       print("Failed to pull: \(error)")
    ///   }
    ///   ```
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
