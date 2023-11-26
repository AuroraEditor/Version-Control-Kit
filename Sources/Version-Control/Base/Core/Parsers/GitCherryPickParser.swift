//
//  GitCherryPickParser.swift
//
//
//  Created by Nanashi Li on 2023/11/19.
//

import Foundation

class GitCherryPickParser {
    private let commits: [Commit]
    private var count: Int = 0

    init(commits: [Commit], 
         count: Int = 0) {
        self.commits = commits
        self.count = count
    }

    func parse(line: String) -> MultiCommitOperationProgress? {
        // Regular expression to match the expected cherry-pick line format
        let cherryPickRe = try! NSRegularExpression(pattern: "^\\[(.*\\s.*)\\]")

        // Range to search in the line
        let range = NSRange(location: 0, length: line.utf16.count)

        // Check if the line matches the expected format
        if let match = cherryPickRe.firstMatch(in: line, options: [], range: range), match.numberOfRanges > 1 {
            self.count += 1  // Increment the count for each matched line

            let summaryIndex = self.count - 1
            let summary = summaryIndex < commits.count ? commits[summaryIndex].summary : ""
            let value = Double(self.count) / Double(commits.count)

            return MultiCommitOperationProgress(
                kind: "multiCommitOperation",
                currentCommitSummary: summary,
                position: self.count,
                totalCommitCount: self.commits.count,
                value: Int(round(value * 100)) / 100
            )
        }

        // Return nil if the line doesn't match
        return nil
    }
}
