//
//  GitRebaseParser.swift
//
//
//  Created by Nanashi Li on 2023/11/01.
//

import Foundation

public func formatRebaseValue(value: Double) -> Double {
    // Clamp the value between 0 and 1
    let clampedValue = max(0, min(value, 1))
    // Round to two decimal places
    let roundedValue = (clampedValue * 100).rounded() / 100
    return roundedValue
}

class GitRebaseParser {
    private let commits: [Commit]

    init(commits: [Commit]) {
        self.commits = commits
    }

    func parse(line: String) -> MultiCommitOperationProgress? {
        let rebasingRe = try! NSRegularExpression(pattern: "Rebasing \\((\\d+)/(\\d+)\\)")
        let range = NSRange(location: 0, length: line.utf16.count)

        if let match = rebasingRe.firstMatch(in: line, options: [], range: range),
           match.numberOfRanges == 3,
           let rebasedCommitCountRange = Range(match.range(at: 1), in: line),
           let totalCommitCountRange = Range(match.range(at: 2), in: line),
           let rebasedCommitCount = Int(line[rebasedCommitCountRange]),
           let totalCommitCount = Int(line[totalCommitCountRange]) {

            let currentCommitSummary = commits.indices.contains(rebasedCommitCount - 1) ? commits[rebasedCommitCount - 1].summary : ""
            let progress = Double(rebasedCommitCount) / Double(totalCommitCount)
            let value = formatRebaseValue(value: progress)

            return MultiCommitOperationProgress(
                kind: "multiCommitOperation",
                currentCommitSummary: currentCommitSummary,
                position: rebasedCommitCount,
                totalCommitCount: totalCommitCount,
                value: Int(value)
            )
        }
        return nil
    }
}
