//
//  GitProcess.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

struct GitProcess {

//    func executionOptionsWithProgress(
//        options: IGitExecutionOptions, 
//        parser: GitProgressParser,
//        progressCallback: @escaping (GitProgressKind) -> Void
//    ) throws -> IGitExecutionOptions {
//        var lfsProgressPath: String? = nil
//        var env = [String: String]()
//
//        if options.trackLFSProgress ?? false {
//            do {
//                lfsProgressPath = try createLFSProgressFile()
//                env["GIT_LFS_PROGRESS"] = lfsProgressPath
//            } catch {
//                print("Error writing LFS progress file", error)
//                env["GIT_LFS_PROGRESS"] = nil
//            }
//        }
//
//        return merge(options, IGitExecutionOptions(
//            processCallback: createProgressProcessCallback(
//                parser: parser, 
//                lfsProgressPath: lfsProgressPath,
//                progressCallback: progressCallback
//            ),
//            env: merge(options.env, env)
//        ))
//    }
//
//    func createProgressProcessCallback(parser: GitProgressParser, 
//                                       lfsProgressPath: String?,
//                                       progressCallback: @escaping (GitProgressKind) -> Void) -> (Process) -> Void {
//        return { process in
//            var lfsProgressActive = false
//
//            if let lfsProgressPath = lfsProgressPath {
//                let lfsParser = GitLFSProgressParser()
//                let disposable = tailByLine(lfsProgressPath) { line in
//                    let progress = lfsParser.parse(line)
//
//                    if progress.kind == "progress" {
//                        lfsProgressActive = true
//                        progressCallback(progress)
//                    }
//                }
//
//                process.terminationHandler = { _ in
//                    disposable.dispose()
//                    // the order of these callbacks is important because
//                    // - unlink can only be done on files
//                    // - rmdir can only be done when the directory is empty
//                    // - we don't want to surface errors to the user if something goes
//                    // wrong (these files can stay in TEMP and be cleaned up eventually)
//                    do {
//                        try FileManager.default.removeItem(atPath: lfsProgressPath)
//                        let directory = (lfsProgressPath as NSString).deletingLastPathComponent
//                        try? FileManager.default.removeItem(atPath: directory)
//                    } catch {
//                        // Handle any errors here as needed
//                    }
//                }
//            }
//
//            if let stderr = process.standardError {
//                let lineReader = LineReader(stream: stderr)
//
//                while let line = lineReader.readLine() {
//                    let progress = parser.parse(line)
//
//                    if lfsProgressActive {
//                        // While we're sending LFS progress, we don't want to mix
//                        // any non-progress events in with the output, or we'll get
//                        // flickering between the indeterminate LFS progress and
//                        // the regular progress.
//                        if progress.kind == "context" {
//                            continue
//                        }
//
//                        let title = progress.details.title
//                        let done = progress.details.done
//
//                        // The 'Filtering content' title happens while the LFS
//                        // filter is running, and when it's done, we know that the
//                        // filter is done, but until then, we don't want to display
//                        // it for the same reason that we don't want to display
//                        // the context above.
//                        if title == "Filtering content" {
//                            if done {
//                                lfsProgressActive = false
//                            }
//                            continue
//                        }
//                    }
//
//                    progressCallback(.progress(progress))
//                }
//            }
//        }
//    }
}
