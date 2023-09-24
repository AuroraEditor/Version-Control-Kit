//
//  GitBranch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/17.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

/// Struct to hold the number of commits a revision range is ahead and behind.
public struct IAheadBehind {
    /// The number of commits ahead of the revision range.
    let ahead: Int
    
    /// The number of commits behind the revision range.
    let behind: Int
}

/// Struct to hold the result of comparing two references in a Git repository.
struct ICompareResult {
    /// The number of commits ahead of the reference being compared to.
    let ahead: Int
    
    /// The number of commits behind the reference being compared to.
    let behind: Int
    
    /// An array of `Commit` objects representing individual commits involved in the comparison.
    let commits: [Commit]
}

/// Struct to hold basic data about a Git branch and the branch it's tracking.
struct ITrackingBranch {
    /// The reference (name) of the branch.
    let ref: String
    
    /// The SHA (hash) of the branch.
    let sha: String
    
    /// The reference (name) of the upstream branch it's tracking.
    let upstreamRef: String
    
    /// The SHA (hash) of the upstream branch.
    let upstreamSha: String
}

/// Struct to hold basic data about the latest commit on a Git branch.
struct IBranchTip {
    /// The SHA (hash) of the latest commit.
    let sha: String
    
    /// Information about the author of the latest commit.
    let author: CommitIdentity
}

/// Enum to represent different starting points for creating a Git branch.
enum StartPoint: String {
    /// Create the branch from the current branch.
    case currentBranch = "CurrentBranch"
    
    /// Create the branch from the default branch.
    case defaultBranch = "DefaultBranch"
    
    /// Create the branch from the HEAD.
    case head = "Head"
    
    /// Create the branch from the upstream default branch.
    case upstreamDefaultBranch = "UpstreamDefaultBranch"
}


/// Enum to represent the type of a Git branch.
enum BranchType: Int {
    /// Represents a local branch.
    case local = 0
    
    /// Represents a remote branch.
    case remote = 1
}

struct Branch {
    let name: String
    let upstream: String?
    let tip: IBranchTip
    let type: BranchType
    let ref: String
    
    /**
     * A branch as loaded from Git.
     *
     * @param name The short name of the branch. E.g., `main`.
     * @param upstream The remote-prefixed upstream name. E.g., `origin/main`.
     * @param tip Basic information (sha and author) of the latest commit on the branch.
     * @param type The type of branch, e.g., local or remote.
     * @param ref The canonical ref of the branch
     */
    init(name: String,
         upstream: String?,
         tip: IBranchTip,
         type: BranchType,
         ref: String) {
        self.name = name
        self.upstream = upstream
        self.tip = tip
        self.type = type
        self.ref = ref
    }
    
    /** The name of the upstream's remote. */
    var upstreamRemoteName: String? {
        guard let upstream = self.upstream else {
            return nil
        }
        
        let pieces = upstream.split(separator: "/")
        if pieces.count >= 2 {
            return String(pieces[0])
        }
        
        return nil
    }
    
    /** The name of remote for a remote branch. If local, will return null. */
    var remoteName: String? {
        if self.type == .local {
            return nil
        }
        
        let pieces = self.ref.split(separator: "/")
        if pieces.count == 4 && pieces[0] == "refs" && pieces[1] == "remotes" {
            return String(pieces[2])
        } else {
            // This shouldn't happen, the remote ref should always be prefixed
            // with refs/remotes
            fatalError("Remote branch ref has unexpected format: \(self.ref)")
        }
    }
    
    /**
     * The name of the branch's upstream without the remote prefix.
     */
    var upstreamWithoutRemote: String? {
        if let upstream = self.upstream {
            return removeRemotePrefix(name: upstream)
        }
        
        return nil
    }
    
    /**
     * The name of the branch without the remote prefix. If the branch is a local
     * branch, this is the same as its `name`.
     */
    var nameWithoutRemote: String {
        if self.type == .local {
            return self.name
        } else {
            let withoutRemote = removeRemotePrefix(name: self.name)
            return withoutRemote ?? self.name
        }
    }
    
    /**
     * Gets a value indicating whether the branch is a remote branch belonging to
     * one of Desktop's automatically created (and pruned) fork remotes. I.e. a
     * remote branch from a branch which starts with `auroraeditor-`.
     *
     * We hide branches from our known Desktop for remotes as these are considered
     * plumbing and can add noise to everywhere in the user interface where we
     * display branches as forks will likely contain duplicates of the same ref
     * names
     **/
    var isDesktopForkRemoteBranch: Bool {
        return self.type == .remote && self.name.hasPrefix("auroraeditor-")
    }
}

