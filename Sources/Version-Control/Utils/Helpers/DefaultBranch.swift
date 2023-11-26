//
//  DefaultBranch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct DefaultBranch {

    /// The default branch name that GitHub Desktop will use when
    /// initializing a new repository.
    private let defaultBranchInAE = "main"

    /// The name of the Git configuration variable which holds what
    /// branch name Git will use when initializing a new repository.
    private let defaultBranchSettingName = "init.defaultBranch"

    /// The branch names that Aurora Editor shows by default as radio buttons on the
    /// form that allows users to change default branch name.
    public let suggestedBranchNames: [String] = ["main, master"]

    public init() {}

    /// Returns the configured default branch when creating new repositories
    public func getConfiguredDefaultBranch() throws -> String? {
        // TODO: Bug where global config value is not being processed correctly
        return try Config().getGlobalConfigValue(name: defaultBranchSettingName)
    }

    /// Returns the configured default branch when creating new repositories
    public func getDefaultBranch() -> String {
        // return try getConfiguredDefaultBranch() ?? defaultBranchInAE
        return defaultBranchInAE
    }

    /// Sets the configured default branch when creating new repositories.
    ///
    /// @param branchName - The default branch name to use.
    public func setDefaultBranch(branchName: String) throws -> String {
        return try Config().setGlobalConfigValue(name: defaultBranchSettingName,
                                    value: branchName)
    }

    public func findDefaultBranch(directoryURL: URL,
                                  branches: [GitBranch],
                                  defaultRemoteName: String?) throws -> GitBranch? {
        let remoteName: String?

        // TODO: Find a way to get upstream name
        remoteName = defaultRemoteName

        let remoteHead = remoteName != nil ? try Remote().getRemoteHEAD(directoryURL: directoryURL,
                                                                        remote: remoteName!) : nil

        let defaultBranchName = remoteHead ?? getDefaultBranch()
        let remoteRef = remoteHead != nil ? "\(remoteName!)/\(remoteHead!)" : nil

        var localHit: GitBranch?
        var localTrackingHit: GitBranch?
        var remoteHit: GitBranch?

        for branch in branches {
            if branch.type == .local {
                if branch.name == defaultBranchName {
                    localHit = branch
                }

                if let remoteRef = remoteRef, branch.upstream == remoteRef {
                    // Give preference to local branches that target the upstream
                    // default branch that also match the name. In other words, if there
                    // are two local branches which both track the origin default branch
                    // we'll prefer a branch which is also named the same as the default
                    // branch name.
                    if localTrackingHit == nil || branch.name == defaultBranchName {
                        localTrackingHit = branch
                    }
                }
            } else if let remoteRef = remoteRef, branch.name == remoteRef {
                remoteHit = branch
            }
        }

        // When determining what the default branch is we give priority to local
        // branches tracking the default branch of the contribution target (think
        // origin) remote, then we consider local branches that are named the same
        // as the default branch, and finally we look for the remote branch
        // representing the default branch of the contribution target
        return localTrackingHit ?? localHit ?? remoteHit
    }

}
