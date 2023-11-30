//
//  File.swift
//
//
//  Created by Nanashi Li on 2022/10/05.
//

import Foundation
import CryptoKit

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

    func substring(with range: NSRange) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: range.length)
        return String(self[startIndex..<endIndex])
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

    func urlEncode(_ parameters: [String: Any]) -> String? {
        var components = URLComponents()
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        return components.percentEncodedQuery
    }

    func urlEncode() -> String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    func stdout() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", self]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if let stdoutString = String(data: stdoutData, encoding: .utf8) {
            return stdoutString
        } else {
            throw NSError(domain: "Error converting stdout data to string", code: 0, userInfo: nil)
        }
    }

    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }

    /// Returns a MD5 encrypted String of the input String
    ///
    /// - Parameters:
    ///   - trim: If `true` the input string will be trimmed from whitespaces and new-lines. Defaults to `false`.
    ///   - caseSensitive: If `false` the input string will be converted to lowercase characters. Defaults to `true`.
    /// - Returns: A String in HEX format
    func md5(trim: Bool = false, caseSensitive: Bool = true) -> String {
        var string = self

        // trim whitespaces & new lines if specifiedå
        if trim { string = string.trimmingCharacters(in: .whitespacesAndNewlines) }

        // make string lowercased if not case sensitive
        if !caseSensitive { string = string.lowercased() }

        // compute the hash
        // (note that `String.data(using: .utf8)!` is safe since it will never fail)
        let computed = Insecure.MD5.hash(data: string.data(using: .utf8)!)

        // map the result to a hex string and return
        return computed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func firstMatch(for pattern: String) -> NSTextCheckingResult? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            return regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self))
        } catch {
            return nil
        }
    }

    func matchedSubstring(for result: NSTextCheckingResult, at index: Int) -> String? {
        let range = result.range(at: index)
        if range.location != NSNotFound {
            return String(self[Range(range, in: self)!])
        }
        return nil
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
