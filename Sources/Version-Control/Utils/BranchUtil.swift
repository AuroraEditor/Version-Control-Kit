//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/05.
//

import Foundation

public struct BranchUtil {

    public init() {}

    /**
     Merges local and remote Git branches into a single array of Git \
     branches that includes branches with upstream relationships.

     - Parameter branches: An array of `GitBranch` instances to be merged.
     - Returns: An array of `GitBranch` instances containing both local and \
                remote branches with their respective upstream branches.

     This function takes an array of `GitBranch` instances and categorizes them into local and remote branches. 
     It then creates a merged array that includes both types of branches along with their respective upstream branches.
     If a local branch has an associated upstream branch, it is included in the result. For remote branches,
     if the corresponding local branch is already added to the result, it is not added again to avoid duplication.
     */
    public func mergeRemoteAndLocalBranches(branches: [GitBranch]) -> [GitBranch] {
        var localBranches = [GitBranch]()
        var remoteBranches = [GitBranch]()

        for branch in branches {
            if branch.type == .local {
                localBranches.append(branch)
            } else if branch.type == .remote {
                remoteBranches.append(branch)
            }
        }

        var upstreamBranchesAdded = Set<String>()
        var allBranchesWithUpstream = [GitBranch]()

        for branch in localBranches {
            allBranchesWithUpstream.append(branch)

            if let upstream = branch.upstream {
                upstreamBranchesAdded.insert(upstream)
            }
        }

        for branch in remoteBranches {
            // This means we already added the local branch of this remote branch, so
            // we don't need to add it again.
            if upstreamBranchesAdded.contains(branch.name) {
                continue
            }

            allBranchesWithUpstream.append(branch)
        }

        return allBranchesWithUpstream
    }
}
