//
//  GitDelimiterParser.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

/**
 A utility struct for parsing Git output with custom delimiters.
 */
struct GitDelimiterParser {

    /**
     * Create a new parser suitable for parsing --format output from commands such
     * as `git log`, `git stash`, and other commands that are not derived from
     * `ref-filter`.
     *
     * Returns a tuple with the arguments that need to be appended to the git
     * call and the parse function itself
     *
     * - Parameter fields: A dictionary keyed on the friendly name of the value being
     *                     parsed with the value being the format string of said value.
     *
     *                     Example:
     *
     *                     `let (args, parse) = createLogParser(["sha": "%H"])`
     */
    func createLogParser<T: Hashable>(_ fields: [T: String]) -> (formatArgs: [String], parse: (String) -> [[T: String]]) {
        let keys = Array(fields.keys)
        let format = fields.values.joined(separator: "%x00")
        let formatArgs = ["-z", "--format=\(format)"]

        let parse: (String) -> [[T: String]] = { value in
            let records = value.components(separatedBy: "\0")
            var entries = [[T: String]]()

            for i in stride(from: 0, to: records.count - keys.count, by: keys.count) {
                var entry = [T: String]()
                for (ix, key) in keys.enumerated() {
                    entry[key] = records[i + ix]
                }
                entries.append(entry)
            }

            return entries
        }

        return (formatArgs, parse)
    }

    /**
     * Create a new parser suitable for parsing --format output from commands such
     * as `git for-each-ref`, `git branch`, and other commands that are not derived
     * from `git log`.
     *
     * Returns a tuple with the arguments that need to be appended to the git
     * call and the parse function itself
     *
     * - Parameter fields: A dictionary keyed on the friendly name of the value being
     *                     parsed with the value being the format string of said value.
     *
     *                     Example:
     *
     *                     `let (args, parse) = createForEachRefParser(["sha": "%(objectname)"])`
     */
    func createForEachRefParser<T: Hashable>(_ fields: [T: String]) -> (formatArgs: [String], parse: (String) -> [[T: String]]) {
        let keys = Array(fields.keys)
        let format = fields.values.joined(separator: "%00")
        let formatArgs = ["--format=%00\(format)%00"]

        let parse: (String) -> [[T: String]] = { value in
            let records = value.components(separatedBy: "\0")
            var entries = [[T: String]]()

            var entry: [T: String]?
            var consumed = 0

            // start at 1 to avoid 0 modulo X problem. The first record is guaranteed
            // to be empty anyway (due to %00 at the start of --format)
            for i in 1..<(records.count - 1) {
                if i % (keys.count + 1) == 0 {
                    if records[i] != "\n" {
                        fatalError("Expected newline")
                    }
                    continue
                }

                entry = entry ?? [T: String]()
                let key = keys[consumed % keys.count]
                entry![key] = records[i]
                consumed += 1

                if consumed % keys.count == 0 {
                    print(entry!)
                    entries.append(entry!)
                    entry = nil
                }
            }

            return entries
        }

        return (formatArgs, parse)
    }
}
