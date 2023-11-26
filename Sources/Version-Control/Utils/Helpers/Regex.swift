//
//  Regex.swift
//
//
//  Created by Nanashi Li on 2023/10/29.
//

import Foundation

/**
 This class provides methods to find and extract regex matches and their captured groups from a given text using NSRegularExpression.
 */
class Regex {

    init() {}

    /**
     Get captured groups from regex matches within a given text.

     - Parameters:
     - text: The input string to search for matches and captures.
     - expression: The regular expression to use for matching. It should have the global option.

     - Returns: An array of arrays of strings representing the captured groups from each match. The outer array contains one element for each match, and the inner arrays contain the captured strings.
     */
    func getCaptures(text: String, expression: NSRegularExpression) -> [[String]] {
        let matches = getMatches(text: text, expression: expression)
        var captures: [[String]] = []

        for match in matches {
            let capturedStrings = (1..<match.numberOfRanges).map { match.range(at: $0) }
                .compactMap { Range($0, in: text).map { String(text[$0]) } }
            captures.append(capturedStrings)
        }

        return captures
    }

    /**
     Get all regex matches within a body of text.

     - Parameters:
     - text: The input string to search for matches.
     - expression: The regular expression to use for matching. It should have the global option.

     - Returns: An array of NSTextCheckingResult objects representing the matched ranges in the text. Each result corresponds to a single match found in the text.
     */
    func getMatches(text: String, expression: NSRegularExpression) -> [NSTextCheckingResult] {
        let range = NSRange(text.startIndex..., in: text)
        let matches = expression.matches(in: text, range: range)
        return matches
    }
}
