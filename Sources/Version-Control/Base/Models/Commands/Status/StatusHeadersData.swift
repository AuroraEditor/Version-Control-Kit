//
//  StatusHeadersData.swift
//
//
//  Created by Nanashi Li on 2023/11/21.
//

import Foundation

struct StatusHeadersData {
    let currentBranch: String?
    let currentUpstreamBranch: String?
    let currentTip: String?
    let branchAheadBehind: IAheadBehind?
    let match: [String]?

    public init() {
        self.currentBranch = nil
        self.currentUpstreamBranch = nil
        self.currentTip = nil
        self.branchAheadBehind = nil
        self.match = nil
    }

    public init(currentBranch: String?, 
                currentUpstreamBranch: String?,
                currentTip: String?,
                branchAheadBehind: IAheadBehind?,
                match: [String]?) {
        self.currentBranch = currentBranch
        self.currentUpstreamBranch = currentUpstreamBranch
        self.currentTip = currentTip
        self.branchAheadBehind = branchAheadBehind
        self.match = match
    }

}
