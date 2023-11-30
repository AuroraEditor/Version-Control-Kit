//
//  Blob.swift
//
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public struct Blob {

    public init() {}

    /// Retrieves the contents of a file at a specified commitish from a git repository.
    ///
    /// This function executes a shell process that runs the `git show` command to fetch the contents
    /// of the file at the given commitish. It constructs the appropriate command, executes it, and returns the data.
    /// If the process encounters an error, it throws an `NSError` with the termination status of the process.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - commitish: The name of the commit/branch/tag from which to fetch the file.
    ///   - path: The path to the file within the git repository.
    /// - Returns: A `Data` object containing the contents of the file.
    /// - Throws: An error if the git command fails or the process encounters an error.
    ///
    /// Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileData = try getBlobContents(directoryURL: directoryURL,
    ///                                    commitish: "main",
    ///                                    path: "path/to/file.txt")
    /// ```
    func getBlobContents(directoryURL: URL,
                         commitish: String,
                         path: String) throws -> Data {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", directoryURL.relativePath.escapedWhiteSpaces(), "show", "\(commitish):\(path)"]
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "", code: Int(process.terminationStatus), userInfo: nil)
        }

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

    /// Retrieves a portion of the contents of a file at a specified commitish within a git repository.
    ///
    /// This function calls `getPartialBlobContentsCatchPathNotInRef` internally to obtain the data.
    /// It passes all the parameters through to this function and returns the partial data, if available.
    /// If the file path does not exist in the reference, it propagates the thrown error from the internal call.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - commitish: The name of the commit/branch/tag from which to fetch the file.
    ///   - path: The path to the file within the git repository.
    ///   - length: The maximum length of data to return.
    /// - Returns: A `Data` object containing up to the specified length of the file's contents, or nil if an error occurred.
    /// - Throws: An error if the internal function call throws.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileData = try getPartialBlobContents(directoryURL: directoryURL,
    ///                                           commitish: "main",
    ///                                           path: "path/to/file.txt",
    ///                                           length: 1024)
    /// ```
    func getPartialBlobContents(directoryURL: URL,
                                commitish: String,
                                path: String,
                                length: Int) throws -> Data? {
        try getPartialBlobContentsCatchPathNotInRef(directoryURL: directoryURL,
                                                           commitish: commitish,
                                                           path: path,
                                                           length: length)
    }

    /// Attempts to retrieve a portion of the contents of a file from a git repository at a specific commitish.
    /// If the file path is not found in the reference, it throws an error indicating this.
    ///
    /// The function sets up a subprocess to run the `git show` command for the file at the given commitish.
    /// It captures both the standard output and standard error to handle the data and any potential errors.
    /// If an error message is detected that indicates the path does not exist in the given commitish,
    /// an error is thrown. Otherwise, it returns the file data up to the specified length, or nil if the
    /// process exits with a non-zero status.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory corresponding to the git repository.
    ///   - commitish: The name of the commit/branch/tag from which to fetch the file.
    ///   - path: The path to the file within the git repository.
    ///   - length: The maximum length of data to return.
    /// - Returns: A `Data` object containing a portion of the file's contents, or nil if an error occurred.
    /// - Throws: An error if the file path is not found in the given commitish.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileData = try getPartialBlobContentsCatchPathNotInRef(directoryURL: directoryURL,
    ///                                                            commitish: "main",
    ///                                                            path: "path/to/file.txt",
    ///                                                            length: 1024)
    /// ```
    func getPartialBlobContentsCatchPathNotInRef(directoryURL: URL,
                                                 commitish: String,
                                                 path: String,
                                                 length: Int) throws -> Data? {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git",
                             "-C",
                             directoryURL.relativePath.escapedWhiteSpaces(),
                             "show",
                             "\(commitish):\(path)"]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty {
            let errorString = String(decoding: errorData, as: UTF8.self)
            if errorString.contains("fatal: Path") && errorString.contains("exists on disk, but not in") {
                throw NSError(domain: "Path exists but not in ref", code: 1)
            }
        }

        if process.terminationStatus != 0 {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if outputData.count > length {
            return outputData.subdata(in: 0..<length)
        }

        return outputData
    }
}
