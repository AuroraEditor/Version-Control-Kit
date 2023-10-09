//
//  RemoveRemotePrefix.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/// Remove the remote prefix from a branch name.
///
/// If a branch name includes a remote prefix, \
/// this function extracts the branch name itself by removing the remote prefix. \
/// If no prefix is found, it returns `nil`.
///
/// - Parameter name: The branch name that may include a remote prefix.
///
/// - Returns: The branch name without the remote prefix, or `nil` if no remote prefix is present in the input name.
///
/// - Example:
///   ```swift
///   let branchName = "origin/main" // Replace with the branch name
///   let extractedBranch = removeRemotePrefix(name: branchName)
///   if let branch = extractedBranch {
///       print("Extracted Branch: \(branch)")
///   } else {
///       print("No remote prefix found.")
///   }
///   ```
///
/// - Note:
///   The remote prefix typically includes the name of the remote repository and a forward slash (`/`). \
///   This function is useful for extracting the local branch name from a branch name that includes the remote prefix.
///
/// - Warning:
///   Ensure that the input `name` is a valid branch name or includes a remote prefix to avoid unexpected results.
///
/// - Returns: The extracted branch name or `nil` if no remote prefix is present in the input name.
func removeRemotePrefix(name: String) -> String? {
    let regexPattern = #".*?/(.*)"#

    if let regex = try? NSRegularExpression(pattern: regexPattern, options: []) {
        if let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.utf16.count)) {
            let remoteBranch = (name as NSString).substring(with: match.range(at: 1))
            return remoteBranch
        }
    }

    return nil
}
