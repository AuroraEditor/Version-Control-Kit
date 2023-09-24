//
//  CommitIdentity.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 * A tuple of name, email, and date for the author or commit
 * info in a commit.
 */
struct CommitIdentity {
    let name: String
    let email: String
    let date: Date
    let tzOffset: Int

    // Initialize the struct
    init(name: String, email: String, date: Date, tzOffset: Int = TimeZone.current.secondsFromGMT()) {
        self.name = name
        self.email = email
        self.date = date
        self.tzOffset = tzOffset
    }

    /**
     * Parses a Git ident string (GIT_AUTHOR_IDENT or GIT_COMMITTER_IDENT)
     * into a commit identity. Throws an error if identify string is invalid.
     */
    static func parseIdentity(identity: String) throws -> CommitIdentity {
        // See fmt_ident in ident.c:
        //  https://github.com/git/git/blob/3ef7618e6/ident.c#L346
        //
        // Format is "NAME <EMAIL> DATE"
        //  Jane Doe <jane.doe@gmail.com> 1475670580 +0200
        //
        // Note that `git var` will strip any < and > from the name and email, see:
        //  https://github.com/git/git/blob/3ef7618e6/ident.c#L396
        //
        // Note also that this expects a date formatted with the RAW option in git see:
        //  https://github.com/git/git/blob/35f6318d4/date.c#L191
        let pattern = #"^(.*?) <(.*?)> (\d+) (\+|-)?(\d{2})(\d{2})"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: identity, options: [], range: NSRange(location: 0, length: identity.utf16.count)) {
                let name = (identity as NSString).substring(with: match.range(at: 1))
                let email = (identity as NSString).substring(with: match.range(at: 2))
                let timestamp = TimeInterval((identity as NSString).substring(with: match.range(at: 3))) ?? 0

                // Convert seconds since epoch to milliseconds
                let date = Date(timeIntervalSince1970: timestamp)

                // Extract the timezone offset
                let tzSign = (identity as NSString).substring(with: match.range(at: 4)) == "-" ? -1 : 1
                let tzHH = (identity as NSString).substring(with: match.range(at: 5))
                let tzmm = (identity as NSString).substring(with: match.range(at: 6))

                if let tzHours = Int(tzHH), let tzMinutes = Int(tzmm) {
                    let tzOffset = tzSign * (tzHours * 60 + tzMinutes)
                    
                    return CommitIdentity(name: name, email: email, date: date, tzOffset: tzOffset)
                }
            }
        }

        throw NSError(domain: "", code: 0, userInfo: ["errorDescription": "Couldn't parse identity \(identity)"])
    }

    // Convert the struct to a string
    func toString() -> String {
        return "\(name) <\(email)>"
    }
}
