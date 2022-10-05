//
//  File.swift
//  
//
//  Created by Nanashi Li on 2022/10/05.
//

import Foundation

extension String {

    /// Removes all `new-line` characters in a `String`
    /// - Returns: A String
    public func removingNewLines() -> String {
        self.replacingOccurrences(of: "\n", with: "")
    }

    /// Removes all `space` characters in a `String`
    /// - Returns: A String
    public func removingSpaces() -> String {
        self.replacingOccurrences(of: " ", with: "")
    }

    public func escapedWhiteSpaces() -> String {
        self.replacingOccurrences(of: " ", with: "\\ ")
    }

    private func index(from: Int) -> Index {
        return self.index(self.startIndex, offsetBy: from)
    }

    public func substring(_ toIndex: Int) -> String {
        let index = index(from: toIndex)
        return String(self[..<index])
    }

    /// Get all regex matches within a body of text
    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

extension StringProtocol where Index == String.Index {

    func ranges<T: StringProtocol>(
        of substring: T,
        options: String.CompareOptions = [],
        locale: Locale? = nil
    ) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let result = range(
            of: substring,
            options: options,
            range: (ranges.last?.upperBound ?? startIndex)..<endIndex,
            locale: locale) {
            ranges.append(result)
        }
        return ranges
    }
}
