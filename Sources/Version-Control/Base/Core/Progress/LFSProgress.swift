//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/12.
//

import Foundation

struct IFileProgress {
    /// The number of bytes that have been transferred for this file.
    var transferred: Int

    /// The total size of the file in bytes.
    var size: Int

    /// Whether this file has been transferred fully.
    var done: Bool
}

struct LFSProgress {

    private var files = [String: IFileProgress]()

    let LFSProgressLineRe = try! NSRegularExpression(pattern: "^(.+?)\\s{1}(\\d+)\\/(\\d+)\\s{1}(\\d+)\\/(\\d+)\\s{1}(.+)$", options: [])

    func createLFSProgressFile() throws -> String {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let lfsProgressURL = tempDirectoryURL.appendingPathComponent("AuroraEditor-lfs-progress-\(UUID().uuidString)")

        // Ensure the directory exists
        try FileManager.default.createDirectory(at: lfsProgressURL.deletingLastPathComponent(), 
                                                withIntermediateDirectories: true)

        // Create the file if it does not exist
        if !FileManager.default.fileExists(atPath: lfsProgressURL.path) {
            FileManager.default.createFile(atPath: lfsProgressURL.path, 
                                           contents: nil)
        } else {
            // If file exists, throw an error
            throw NSError(domain: "com.auroraeditor.editor",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "File already exists"])
        }

        return lfsProgressURL.path
    }

    mutating func parse(line: String) -> GitParsingResult {
        let matches = LFSProgressLineRe.matches(in: line, range: NSRange(line.startIndex..., in: line))

        guard let match = matches.first, match.numberOfRanges == 7,
              let directionRange = Range(match.range(at: 1), in: line),
              let estimatedFileCountRange = Range(match.range(at: 3), in: line),
              let fileTransferredRange = Range(match.range(at: 4), in: line),
              let fileSizeRange = Range(match.range(at: 5), in: line),
              let fileNameRange = Range(match.range(at: 6), in: line),
              let estimatedFileCount = Int(line[estimatedFileCountRange]),
              let fileTransferred = Int(line[fileTransferredRange]),
              let fileSize = Int(line[fileSizeRange]) else {
            return IGitOutput(kind: "context", percent: 0, text: line)
        }

        let direction = String(line[directionRange])
        let fileName = String(line[fileNameRange])
        files[fileName] = IFileProgress(transferred: fileTransferred, size: fileSize, done: fileTransferred == fileSize)

        var totalTransferred = 0
        var totalEstimated = 0
        var finishedFiles = 0

        let fileCount = max(estimatedFileCount, files.count)

        for file in files.values {
            totalTransferred += file.transferred
            totalEstimated += file.size
            finishedFiles += file.done ? 1 : 0
        }

        let transferProgress = "\(totalTransferred) / \(totalEstimated)"

        let percentComplete = totalEstimated > 0 ? Int((Double(totalTransferred) / Double(totalEstimated)) * 100) : nil

        let verb = directionToHumanFacingVerb(direction: direction)
        let info = IGitProgressInfo(title: "\(verb) \"\(fileName)\"",
                                    value: totalTransferred,
                                    total: totalEstimated,
                                    percent: percentComplete,
                                    done: finishedFiles == fileCount,
                                    text: "\(verb) \(fileName) (\(finishedFiles) out of an estimated \(fileCount) completed, \(transferProgress))")

        return IGitProgress(kind: "progress", percent: info.percent ?? 0, details: info)
    }

    private func directionToHumanFacingVerb(direction: String) -> String {
        switch direction {
        case "download":
            return "Downloading"
        case "upload":
            return "Uploading"
        case "checkout":
            return "Checking out"
        default:
            return "Downloading"
        }
    }
}
