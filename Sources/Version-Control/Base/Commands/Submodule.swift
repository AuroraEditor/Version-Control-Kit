//
//  Submodule.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Submodule {

    public init(){}

    func listSubmodules(directoryURL: URL) throws -> [SubmoduleEntry] {
        let submodulesFile = FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(".gitmodules").path)
        var isDirectory: ObjCBool = true
        let submodulesDir = FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(".git/modules").path,
                                                           isDirectory: &isDirectory)

        if !submodulesFile && !submodulesDir {
            print("No submodules found. Skipping \"git submodule status\"")
            return []
        }

        let gitArgs = ["submodule", "status", "--"]
        let result = try GitShell().git(args: gitArgs,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 128])))

        if result.exitCode == 128 {
            // Unable to parse submodules in the repository, giving up
            return []
        }

        var submodules = [SubmoduleEntry]()

        // entries are of the format:
        //  1eaabe34fc6f486367a176207420378f587d3b48 git (v2.16.0-rc0)
        //
        // first character:
        //   - " " if no change
        //   - "-" if the submodule is not initialized
        //   - "+" if the currently checked out submodule commit does not match the SHA-1 found
        //         in the index of the containing repository
        //   - "U" if the submodule has merge conflicts
        //
        // then the 40-character SHA represents the current commit
        //
        // then the path to the submodule
        //
        // then the output of `git describe` for the submodule in braces
        // we're not leveraging this in the app, so go and read the docs
        // about it if you want to learn more:
        //
        // https://git-scm.com/docs/git-describe
        let statusRe = try NSRegularExpression(pattern: #".([^ ]+) (.+) \((.+?)\)"#, options: [])

        let stdout = result.stdout
        let range = NSRange(stdout.startIndex..<stdout.endIndex, in: stdout)

        let matches = statusRe.matches(in: stdout, options: [], range: range)

        for match in matches {
            if match.numberOfRanges == 4 {
                let statusRange = match.range(at: 1)
                let shaRange = match.range(at: 2)
                let pathRange = match.range(at: 3)
                let describeRange = match.range(at: 4)

                let status = stdout.substring(statusRange.lowerBound)
                let sha = stdout.substring(shaRange.lowerBound)
                let path = stdout.substring(pathRange.lowerBound)
                let describe = stdout.substring(describeRange.lowerBound)

                submodules.append(SubmoduleEntry(sha: sha, path: path, describe: describe))
            }
        }

        return submodules
    }

    public func resetSubmodulePaths(directoryURL: URL,
                                    paths: [String]) throws {
        if paths.isEmpty {
            return
        }

        var args = [
            "submodule",
            "update",
            "--recursive",
            "--force",
            "--"
        ]

        args.append(contentsOf: paths)

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
    }

}

public class SubmoduleEntry {
    let sha: String
    let path: String
    let describe: String

    init(sha: String, path: String, describe: String) {
        self.sha = sha
        self.path = path
        self.describe = describe
    }
}
