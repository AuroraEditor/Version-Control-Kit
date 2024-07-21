//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/09/25.
//

import Foundation

enum ShellErrors: String, Error {
    // swiftlint:disable:next line_length
    case failedToInitializeRepository = "An error occurred while attempting to initialize the Git repository. Possible reasons for this failure include:\n\n1. The specified directory does not exist or is inaccessible.\n2. Git is not installed on your system, or it is not in the system's PATH.\n3. There may be a conflict with an existing Git repository in the specified directory.\n4. The Git initialization command encountered an unexpected issue."
    // swiftlint:disable:next line_length
    case failedToInstallLFS = "An error occurred while attempting to install Git Large File Storage (LFS). Possible reasons for this failure include:\n\n1. There may be a network issue preventing the installation of Git LFS.\n2. The Git LFS installation command encountered an unexpected issue."
}
