//
//  Update-Ref.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct UpdateRef {

    public init() {}

    /// Update a Git reference (branch or tag) in a local Git repository.
    ///
    /// This function updates the specified Git reference (branch or tag) \ 
    /// in the local Git repository with a new value. \
    /// You must provide the old and new values of the reference and a reason or commit message for the update.
    ///
    /// - Parameters:
    ///   - directoryURL: The local directory URL of the Git repository.
    ///   - ref: The name of the reference (branch or tag) to be updated.
    ///   - oldValue: The old value of the reference.
    ///   - newValue: The new value to set for the reference.
    ///   - reason: A reason or commit message for the update.
    ///
    /// - Throws: An error if there's an issue with executing the Git command or \
    ///           if the specified reference doesn't exist.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///       let referenceToUpdate = "refs/heads/my-feature-branch"
    ///       let oldValue = "abc123"
    ///       let newValue = "def456"
    ///       let updateReason = "Updated feature branch"
    ///       try updateRef(
    ///           directoryURL: directoryURL,
    ///           ref: referenceToUpdate,
    ///           oldValue: oldValue,
    ///           newValue: newValue,
    ///           reason: updateReason
    ///       )
    ///   } catch {
    ///       print("Error: Unable to update the Git reference.")
    ///   }
    public func updateRef(directoryURL: URL,
                          ref: String,
                          oldValue: String,
                          newValue: String,
                          reason: String) throws {
        try ShellClient().run(
            // swiftlint:disable:next line_length
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git update-ref \(ref) \(newValue) \(oldValue) -m \(reason)")
    }

    /// Delete a Git reference (branch or tag) in a local Git repository.
    ///
    /// This function deletes the specified Git reference (branch or tag) in the local Git repository. \
    /// You can optionally provide a reason or commit message for the deletion.
    ///
    /// - Parameters:
    ///   - directoryURL: The local directory URL of the Git repository.
    ///   - ref: The name of the reference (branch or tag) to be deleted.
    ///   - reason: An optional reason or commit message for the deletion.
    ///
    /// - Throws: An error if there's an issue with executing the Git command or \
    ///           if the specified reference doesn't exist.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///       let referenceToDelete = "feature/my-feature-branch"
    ///       let deletionReason = "Obsolete feature branch"
    ///       try deleteRef(directoryURL: directoryURL, ref: referenceToDelete, reason: deletionReason)
    ///   } catch {
    ///       print("Error: Unable to delete the Git reference.")
    ///   }
    public func deleteRef(directoryURL: URL,
                          ref: String,
                          reason: String?) throws {
        var args = ["update-ref", "-d", ref]

        if reason != nil {
            args.append("-m")
            args.append(reason!)
        }
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)")
    }
}
