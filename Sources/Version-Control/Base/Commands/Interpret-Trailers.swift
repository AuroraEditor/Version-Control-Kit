//
//  Interpret-Trailers.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// A representation of a Git commit message trailer.
public protocol ITrailer {
    var token: String { get }
    var value: String { get }
}

public struct Trailer: Codable, ITrailer, Hashable {
    public var token: String = ""
    public var value: String = ""

    public init(token: String, value: String) {
        self.token = token
        self.value = value
    }
}

public struct InterpretTrailers {

    public init() {}

    /// Gets a value indicating whether the trailer token is
    /// Co-Authored-By. Does not validate the token value.
    public func isCoAuthoredByTrailer(trailer: Trailer) -> Bool {
        return trailer.token.lowercased() == "co-authored-by"
    }

    func trimCoAuthorsTrailers(trailers: [Trailer], body: String) -> String {
        var trimmedBody = body

        for trailer in trailers where isCoAuthoredByTrailer(trailer: trailer) {
            let trailerString = "\(trailer.token): \(trailer.value)"
            if let range = trimmedBody.range(of: trailerString) {
                trimmedBody.removeSubrange(range)
            }
        }

        return trimmedBody
    }

    /// Parse a string containing only unfolded trailers produced by
    /// git-interpret-trailers --only-input --only-trailers --unfold or
    /// a derivative such as git log --format="%(trailers:only,unfold)"
    public func parseRawUnfoldedTrailers(trailers: String, seperators: String) -> [Trailer] {
        let lines = trailers.split(separator: "\n")
        var parsedTrailers: [Trailer] = []

        for line in lines {
            let trailer = parseSingleUnfoldedTrailer(line: String(line),
                                                     separators: seperators)

            // swiftlint:disable:next control_statement
            if (trailer != nil) {
                parsedTrailers.append(trailer!)
            }
        }

        return parsedTrailers
    }

    public func parseSingleUnfoldedTrailer(line: String, separators: String) -> Trailer? {
        for separator in separators {
            if let range = line.range(of: String(separator)) {
                let token = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valueIndex = line.index(range.lowerBound, offsetBy: 1)
                if valueIndex < line.endIndex {
                    let value = String(line[valueIndex...]).trimmingCharacters(in: .whitespaces)
                    return Trailer(token: token, value: value)
                }
            }
        }
        return nil
    }

    /// Get a string containing the characters that may be used in this repository
    /// separate tokens from values in commit message trailers. If no specific
    /// trailer separator is configured the default separator (:) will be returned.
    public func getTrailerSeparatorCharacters(directoryURL: URL) throws -> String {
        return try Config().getConfigValue(directoryURL: directoryURL,
                                           name: "trailer.separators") ?? ":"
    }

    /// Extract commit message trailers from a commit message.
    ///
    /// The trailers returned here are unfolded, i.e. they've had their
    /// whitespace continuation removed and are all on one line.
    public func parseTrailers(directoryURL: URL,
                              commitMessage: String) throws -> [ITrailer] {

        let result = try GitShell().git(args: ["interpret-trailers", "--parse"],
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(stdin: commitMessage))

        let trailers = result.stdout

        if trailers.isEmpty {
            return []
        }

        let seperators = try getTrailerSeparatorCharacters(directoryURL: directoryURL)
        return parseRawUnfoldedTrailers(trailers: result.stdout,
                                        seperators: seperators)
    }

    /// Merge one or more commit message trailers into a commit message.
    ///
    /// If no trailers are given this method will simply try to ensure that
    /// any trailers that happen to be part of the raw message are formatted
    /// in accordance with the configuration options set for trailers in
    /// the given repository.
    ///
    /// Note that configuration may be set so that duplicate trailers are
    /// kept or discarded.
    ///
    /// @param directoryURL - The project url in which to run the interpret-
    /// trailers command. Although not intuitive this
    /// does matter as there are configuration options
    /// available for the format, position, etc of commit
    /// message trailers. See the manpage for
    /// git-interpret-trailers for more information.
    ///
    /// @param commitMessage - A commit message with or without existing commit
    /// message trailers into which to merge the trailers
    /// given in the trailers parameter
    ///
    /// @param trailers - Zero or more trailers to merge into the commit message
    ///
    /// @returns - A commit message string where the provided trailers (if)
    /// any have been merged into the commit message using the
    /// configuration settings for trailers in the provided
    /// repository.
    public func mergeTrailers(directoryURL: URL,
                              commitMessage: String,
                              trailers: [ITrailer],
                              unfold: Bool = false) throws -> String {
        var args = ["interpret-trailers"]

        // See https://github.com/git/git/blob/ebf3c04b262aa/Documentation/git-interpret-trailers.txt#L129-L132
        args.append("--no-divider")

        if unfold {
            args.append("--unfold")
        }

        for trailer in trailers {
            args.append("--trailer \(trailer.token)=\(trailer.value)")
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(stdin: commitMessage))

        return result.stdout
    }
}
