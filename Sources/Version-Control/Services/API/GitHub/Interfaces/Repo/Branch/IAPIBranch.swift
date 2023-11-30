//
//  IAPIBranch.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

/**
 Branch information returned by the GitHub API.
 */
public struct IAPIBranch: Codable {
    /**
     The name of the branch stored on the remote.
     
     NOTE: This is NOT a fully-qualified ref (i.e., `refs/heads/main`).
     */
    public let name: String

    /**
     Branch protection settings:
     
     - `true` indicates that the branch is protected in some way.
     - `false` indicates no branch protection set.
     */
    public let protected: Bool
}
