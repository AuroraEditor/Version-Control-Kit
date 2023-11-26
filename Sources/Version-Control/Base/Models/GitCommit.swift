//
//  Commit.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

func shortenSHA(_ sha: String) -> String {
    return String(sha.prefix(9))
}

/// Grouping of information required to create a commit
public protocol ICommitContext {
    /// The summary of the commit message (required)
    var summary: String? { get }
    /// Additional details for the commit message (optional)
    var description: String? { get }
    /// Whether or not it should amend the last commit (optional, default: false)
    var amend: Bool? { get }
    /// An optional array of commit trailers (for example Co-Authored-By trailers)
    /// which will be appended to the commit message in accordance with the Git trailer configuration.
    var trailers: [Trailer]? { get }
}

public struct CommitContext: ICommitContext {
    public var summary: String?
    public var description: String?
    public var amend: Bool?
    public var trailers: [Trailer]?

    public init(summary: String?,
                description: String?,
                amend: Bool?,
                trailers: [Trailer]?) {
        self.summary = summary
        self.description = description
        self.amend = amend
        self.trailers = trailers
    }
}

/// Extract any Co-Authored-By trailers from an array of arbitrary
/// trailers.
public func extractCoAuthors(trailers: [Trailer]) -> [GitAuthor] {
    var coAuthors: [GitAuthor] = []

    for trailer in trailers where InterpretTrailers().isCoAuthoredByTrailer(trailer: trailer) {
        let author = GitAuthor(name: nil, email: nil).parse(nameAddr: trailer.value)
        if author != nil {
            coAuthors.append(author!)
        }
    }

    return coAuthors
}

/// A git commit.
public struct Commit: Codable, Equatable, Identifiable {
    public var id = UUID()

    /// A list of co-authors parsed from the commit message
    /// trailers.
    public var coAuthors: [GitAuthor]?
    /// The commit body after removing coauthors
    public var bodyNoCoAuthors: String?
    /// A value indicating whether the author and the committer
    /// are the same person.
    public var authoredByCommitter: Bool
    /// Whether or not the commit is a merge commit (i.e. has at least 2 parents)
    public var isMergeCommit: Bool

    public var sha: String
    public var shortSha: String
    public var summary: String
    public var body: String
    public var author: CommitIdentity
    public var committer: CommitIdentity
    public var parentSHAs: [String]
    public var trailers: [Trailer]
    public var tags: [String]

    public init(sha: String,
                shortSha: String,
                summary: String,
                body: String,
                author: CommitIdentity,
                commiter: CommitIdentity,
                parentShas: [String],
                trailers: [Trailer],
                tags: [String]) {
        self.sha = sha
        self.shortSha = shortSha
        self.summary = summary
        self.body = body
        self.author = author
        self.committer = commiter
        self.parentSHAs = parentShas
        self.trailers = trailers
        self.tags = tags

        self.coAuthors = extractCoAuthors(trailers: trailers)
        self.authoredByCommitter = (author.name == committer.name && author.email == committer.email)
        self.bodyNoCoAuthors = InterpretTrailers().trimCoAuthorsTrailers(trailers: trailers, body: body)
        self.isMergeCommit = parentShas.count > 1
    }

    public init(sha: String, 
                summary: String) {
        self.sha = sha
        self.summary = summary

        self.shortSha = ""
        self.body = ""
        self.author = CommitIdentity(name: "",
                                     email: "",
                                     date: Date())
        self.committer = CommitIdentity(name: "",
                                        email: "",
                                        date: Date())
        self.parentSHAs = []
        self.trailers = []
        self.tags = []

        self.coAuthors = nil
        self.authoredByCommitter = false
        self.bodyNoCoAuthors = nil
        self.isMergeCommit = false
    }

    public static func == (lhs: Commit, rhs: Commit) -> Bool {
        return lhs.sha == rhs.sha
    }
}
