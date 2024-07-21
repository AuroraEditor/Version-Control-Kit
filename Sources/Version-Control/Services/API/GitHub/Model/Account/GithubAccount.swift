//
//  GithubAccount.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

// Define the Account class
public class Account: Codable, Equatable {
    let login: String
    let endpoint: String
    let token: String
    let emails: [IAPIEmail]
    let avatarURL: String
    let id: Int
    let name: String
    let plan: String?

    public init(login: String,
                endpoint: String,
                token: String,
                emails: [IAPIEmail],
                avatarURL: String,
                id: Int,
                name: String,
                plan: String?
    ) {
        self.login = login
        self.endpoint = endpoint
        self.token = token
        self.emails = emails
        self.avatarURL = avatarURL
        self.id = id
        self.name = name
        self.plan = plan
    }

    func withToken(_ token: String) -> Account {
        return Account(login: self.login,
                       endpoint: self.endpoint,
                       token: token,
                       emails: self.emails,
                       avatarURL: self.avatarURL,
                       id: self.id,
                       name: self.name,
                       plan: self.plan)
    }

    var friendlyName: String {
        return self.name.isEmpty ? self.login : self.name
    }

    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.endpoint == rhs.endpoint && lhs.id == rhs.id
    }
}
