//
//  Description.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

private let gitDescriptionPath = ".git/description"

private let defaultGitDescription = "Unnamed repository; edit this file 'description' to name the repository.\n"

public struct GitDescription {

    public init() {}

    /// Get the project's description from the `.git/description` file.
    ///
    /// This function retrieves the project's description from the `.git/description`
    /// file within a Git repository located at the specified `directoryURL`. \
    /// The description typically provides a brief overview of the project.
    ///
    /// - Parameter directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the description retrieval process.
    ///
    /// - Returns:
    ///   The project's description as a string, or an empty string if the description is not found or cannot be retrieved.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///
    ///   do {
    ///       let projectDescription = try getGitDescription(directoryURL: directoryURL)
    ///       if !projectDescription.isEmpty {
    ///           print("Project Description: \(projectDescription)")
    ///       } else {
    ///           print("Project description not found.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving project description: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function reads the content of the `.git/description` file in the Git repository specified by
    ///   `directoryURL` and returns it as a string. \
    ///   If the description is not found or cannot be retrieved, an empty string is returned.
    public func getGitDescription(directoryURL: URL) throws -> String {
        let path = try String(contentsOf: directoryURL) + gitDescriptionPath

        do {
            let data = try String(contentsOf: URL(string: path)!)
            if data == defaultGitDescription {
                return ""
            }
            return data
        } catch {
            return ""
        }
    }

    /// Write a project's description to the `.git/description` file within a Git repository.
    ///
    /// This function writes the provided `description` to the `.git/description` file within
    /// a Git repository located at the specified `directoryURL`. \
    /// The description typically provides a brief overview of the project.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - description: The project's description to be written to the file.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the description writing process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let projectDescription = "My Awesome Project" // Replace with the desired project description
    ///
    ///   do {
    ///       try writeGitDescription(directoryURL: directoryURL, description: projectDescription)
    ///       print("Project Description has been updated.")
    ///   } catch {
    ///       print("Error writing project description: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function writes the provided `description` to the `.git/description` file
    ///   in the Git repository specified by `directoryURL`. \
    ///   It does so by overwriting the existing content of the file, if any.
    public func writeGitDescription(directoryURL: URL,
                                    description: String) throws {
        let fullPath = try String(contentsOf: directoryURL) + gitDescriptionPath
        try description.write(toFile: fullPath, atomically: false, encoding: .utf8)
    }
}
