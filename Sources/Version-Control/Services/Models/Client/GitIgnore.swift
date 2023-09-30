//
//  GitIgnore.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitIgnore {

    /// Read the contents of the repository's root `.gitignore` file.
    ///
    /// This function reads the contents of the `.gitignore` file located in the root directory of the Git repository. If the `.gitignore` file exists and has content, it will be returned as a string. If there is no `.gitignore` file in the repository root, the function will return `nil`.
    ///
    /// - Parameter directoryURL: The URL of the Git repository directory where the `.gitignore` file is expected to be located.
    ///
    /// - Returns: The contents of the `.gitignore` file as a string if it exists, or `nil` if the file is not present.
    ///
    /// - Throws: An error if there is a problem reading the `.gitignore` file.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/git/repository")
    ///   if let gitIgnoreContents = try readGitIgnoreAtRoot(directoryURL: directoryURL) {
    ///       print("Contents of .gitignore:")
    ///       print(gitIgnoreContents)
    ///   } else {
    ///       print(".gitignore file not found in the repository.")
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have read permissions for the repository directory and that the provided directory is part of a Git repository.
    public func readGitIgnoreAtRoot(directoryURL: URL) throws -> String? {
        let ignorePath = try String(contentsOf: directoryURL) + ".gitignore"
        let content = try String(contentsOf: URL(string: ignorePath)!)
        return content
    }

    /// Persist the given content to the root `.gitignore` file of the repository.
    ///
    /// This function saves the provided text content to the root `.gitignore` file of the Git repository. If the repository root doesn't contain a `.gitignore` file, one will be created with the specified content. If a `.gitignore` file already exists, its contents will be overwritten with the new content.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository directory where the root `.gitignore` file should be located or created.
    ///   - text: The content to be saved to the `.gitignore` file. This content should follow `.gitignore` file format rules.
    ///
    /// - Throws: An error if there is a problem creating, writing, or saving the `.gitignore` file.
    ///
    /// - Note: If the `text` is empty, the `.gitignore` file will be deleted if it exists.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/git/repository")
    ///   let gitIgnoreContents = "*.log\nbuild/"
    ///   try saveGitIgnore(directoryURL: directoryURL, text: gitIgnoreContents)
    ///   ```
    ///
    /// - Important: Ensure that you have write permissions for the repository directory and that the provided directory is part of a Git repository.
    public func saveGitIgnore(directoryURL: URL,
                              text: String) throws {
        let ignorePath = try String(contentsOf: directoryURL) + ".gitignore"

        if text.isEmpty {
            return
        }

        let fileContents = try formatGitIgnoreContents(text: text,
                                                       directoryURL: directoryURL)
        try text.write(to: URL(string: ignorePath)!, atomically: false, encoding: .utf8)
    }

    /// Add the given pattern or patterns to the root `.gitignore` file of the repository.
    ///
    /// This function appends one or more patterns to the root `.gitignore` file of the specified Git repository. The provided patterns will be added to the end of the existing `.gitignore` file, and they will be escaped as necessary to ensure proper matching.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository directory where the root `.gitignore` file is located.
    ///   - patterns: An array of patterns to append to the `.gitignore` file. Each pattern should be on a separate line.
    ///
    /// - Throws: An error if there is a problem reading, updating, or saving the `.gitignore` file.
    ///
    /// - Note: If the `.gitignore` file does not exist in the repository, it will be created with the specified patterns.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/git/repository")
    ///   let patterns = ["*.log", "build/"]
    ///   try appendIgnoreRule(directoryURL: directoryURL, patterns: patterns)
    ///   ```
    ///
    /// - Important: Ensure that you have write permissions for the `.gitignore` file and that the provided directory is part of a Git repository.
    public func appendIgnoreRule(directoryURL: URL, patterns: [String]) throws {
        let text = try readGitIgnoreAtRoot(directoryURL: directoryURL)

        let currentContents = try formatGitIgnoreContents(text: text!,
                                                          directoryURL: directoryURL)

        let newPatternText = patterns.joined(separator: "\n")
        let newText = try formatGitIgnoreContents(text: "\(currentContents)\(newPatternText)",
                                                  directoryURL: directoryURL)

        try saveGitIgnore(directoryURL: directoryURL, text: newText)
    }

    /// Convenience method to add the given file path(s) to the repository's `.gitignore` file.
    ///
    /// This function allows you to append one or more file paths to the `.gitignore` file in the specified repository directory. The provided file paths will be escaped before being added to the `.gitignore` file to ensure they are properly matched.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the `.gitignore` file is located.
    ///   - filePaths: An array of file paths to append to the `.gitignore` file.
    ///
    /// - Throws: An error if there is a problem reading or updating the `.gitignore` file.
    ///
    /// - Note: This function is intended for appending file paths to an existing `.gitignore` file. If the `.gitignore` file does not exist, you should create it first and then use this function to add file paths.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let filePaths = ["*.log", "build/"]
    ///   try appendIgnoreFile(directoryURL: directoryURL, filePath: filePaths)
    ///   ```
    ///
    /// - Important: Ensure that you have write permissions for the `.gitignore` file and that the provided directory is part of a Git repository.
    public func appendIgnoreFile(directoryURL: URL,
                                 filePath: [String]) throws {
        let escapedFilePaths = filePath.map {
            escapeGitSpecialCharacters(pattern: $0)
        }

        return try appendIgnoreRule(directoryURL: directoryURL, patterns: escapedFilePaths)
    }

    /// Escapes special characters in a string for use in a `.gitignore` file pattern.
    ///
    /// This function takes a string pattern and escapes any special characters that are used in `.gitignore` file patterns. The escaped pattern can then be safely used in a `.gitignore` file to match files and directories.
    ///
    /// - Parameter pattern: The string pattern to be escaped.
    ///
    /// - Returns: The escaped string pattern suitable for use in a `.gitignore` file.
    ///
    /// - Note: The special characters that are escaped include `/`, `[`, `]`, `!`, `*`, `#`, and `?`, as they have special meanings in `.gitignore` patterns.
    ///
    /// - Example:
    ///   ```swift
    ///   let pattern = "*.log"
    ///   let escapedPattern = escapeGitSpecialCharacters(pattern: pattern)
    ///   // Use the escapedPattern in a .gitignore file.
    ///   ```
    ///
    /// - Important: The escaped pattern is intended for use in `.gitignore` files. Ensure that you understand how `.gitignore` patterns work in Git repositories.
    public func escapeGitSpecialCharacters(pattern: String) -> String {
        // Define the characters that need to be escaped within a regular expression pattern
        let specialCharacters = "/[\\[\\]!\\*\\#\\?]/"

        // Use regular expression matching and replacement
        let escapedPattern = pattern.replacingOccurrences(
            of: specialCharacters,
            with: "\\\\$0",
            options: .regularExpression
        )

        return escapedPattern
    }

    /// Format the contents of a `.gitignore` file based on the current Git configuration settings.
    ///
    /// This function takes the text contents of a `.gitignore` file and formats it based on the current Git configuration settings, specifically `core.autocrlf` and `core.safecrlf`. Depending on these settings, it may normalize line endings to CRLF (`\r\n`) or LF (`\n`), and it ensures that the file ends with the appropriate line ending based on Git's behavior.
    ///
    /// - Parameters:
    ///   - text: The text contents of the `.gitignore` file to format.
    ///   - directoryURL: The URL of the directory containing the `.gitignore` file.
    ///
    /// - Throws: An error if there was an issue retrieving Git configuration values or formatting the text.
    ///
    /// - Returns: The formatted text contents of the `.gitignore` file.
    ///
    /// - Note: The `core.autocrlf` setting controls how line endings are handled in the working directory, while `core.safecrlf` affects Git's behavior when adding files to the index. This function ensures that the `.gitignore` file adheres to these settings to prevent conflicts and confusion.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let gitIgnoreText = try formatGitIgnoreContents(text: myGitIgnoreText, directoryURL: myProjectDirectoryURL)
    ///       // Use the formatted gitIgnoreText as needed.
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have a valid Git repository and a `.gitignore` file in the specified directory before calling this function.
    func formatGitIgnoreContents(text: String, directoryURL: URL) throws -> String {
        let autocrlf = try Config().getConfigValue(directoryURL: directoryURL, name: "core.autocrlf")
        let safecrlf = try Config().getConfigValue(directoryURL: directoryURL, name: "core.safecrlf")

        if autocrlf == "true" && safecrlf == "true" {
            // Normalize line endings to CRLF (\r\n)
            return text.replacingOccurrences(of: #"\r\n|\n\r|\n|\r"#, with: "\r\n", options: .regularExpression)
        }

        if text.hasSuffix("\n") {
            return text
        }

        if autocrlf == nil {
            // Fall back to Git default behavior (append LF)
            return text + "\n"
        } else {
            let linesEndInCRLF = autocrlf == "true"
            return text + (linesEndInCRLF ? "\n" : "\r\n")
        }
    }
}
