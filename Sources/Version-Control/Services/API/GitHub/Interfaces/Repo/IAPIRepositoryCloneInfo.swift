//
//  IAPIRepositoryCloneInfo.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

// Define the IAPIRepositoryCloneInfo struct
struct IAPIRepositoryCloneInfo {
    
    /** Canonical clone URL of the repository. */
    let url: String
    
    /**
     * Default branch of the repository, if any. This is usually either retrieved
     * from the API for GitHub repositories, or undefined for other repositories.
     */
    let defaultBranch: String?
}
