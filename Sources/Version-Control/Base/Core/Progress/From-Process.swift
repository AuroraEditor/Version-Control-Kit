//
//  From-Process.swift
//
//
//  Created by Nanashi Li on 2023/11/12.
//

import Foundation

struct FromProcess {

    func executionOptionsWithProgress(
        options: IGitExecutionOptions,
        parser: GitProgressParser,
        progressCallback: @escaping (GitParsingResult) -> Void
    ) throws -> IGitExecutionOptions {
        var lfsProgressPath: String?
        var env = [String: String]()
        if options.trackLFSProgress! {
            do {
                lfsProgressPath = try LFSProgress().createLFSProgressFile()
                env["GIT_LFS_PROGRESS"] = lfsProgressPath
            } catch {
                print("Error writing LFS progress file: \(error)")
                env["GIT_LFS_PROGRESS"] = nil
            }
        }

        var mergedEnv = options.env ?? [:]
        mergedEnv.merge(env) { (_, new) in new }

        let mergedOptions = IGitExecutionOptions(env: mergedEnv, trackLFSProgress: options.trackLFSProgress)
        return mergedOptions
    }
}
