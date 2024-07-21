//
//  FileUtils.swift
//
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

public struct FileUtils {

    func writeToTempFile(content: String,
                         tempFileName: String) async throws -> String {
        let tempDir = NSTemporaryDirectory()
        let tempFilePath = (tempDir as NSString).appendingPathComponent(tempFileName)
        try content.write(toFile: tempFilePath, atomically: true, encoding: .utf8)
        return tempFilePath
    }

    func getOldPathOrDefault(file: FileChange) -> String {
        if file.status?.kind == .renamed || file.status?.kind == .copied {
            if let file = file.status as? CopiedOrRenamedFileStatus {
                return file.oldPath
            } else {
                return file.path
            }
        } else {
            return file.path
        }
    }
}
