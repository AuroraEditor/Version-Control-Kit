//
//  BitBucketAPI.swift
//
//
//  Created by Nanashi Li on 2023/10/29.
//

import Foundation

struct BitBucketAPI {
    
    public init(){}

    var bitbucketURL: String = "https://api.bitbucket.org/2.0/"

    func createRepository(
        workspace: IAPIOrganization?,
        name: String,
        description: String,
        isPrivate: Bool,
        completion: @escaping (IAPIFullRepository?) -> Void
    ) {
        let path = workspace != nil ? "repositories/\(workspace!.login)" : "repositories"
        let requestBody: [String: Any] = [
            "name": name,
            "description": description,
            "private": isPrivate
        ]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .POST,
                     parameters: requestBody,
                     completionHandler: { result in
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIFullRepository.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                    }
                case .failure(let error):
                    print("Unable to publish repository. Please check if you have an internet connection and try again.", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Repository Issues

    /**
     * Fetch the issues with the given state that have been created or updated
     * since the given date.
     */
    func fetchIssues(
        owner: String,
        name: String,
        state: APIIssueState,
        completion: @escaping ([IAPIIssue]?) -> Void
    ) {
        let path = "/repositories/\(owner)/\(name)/issues"

        AuroraNetworking()
            .request(baseURL: "https://api.bitbucket.org/2.0/",
                     path: path,
                     headers: [:],
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIIssue].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("fetchIssues: failed for repository \(owner)/\(name)", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Repository Pull Requests

    public func fetchAllOpenPullRequests(
        workspace: String,
        repo: String,
        completion: @escaping ([IBitBucketAPIPullRequest]?) -> Void) {
            let path = "repositories/\(workspace)/\(repo)/pullrequests".urlEncode(["state": "OPEN"])

            AuroraNetworking().request(baseURL: AuroraNetworkingConstants.BitbucketURL,
                                       path: path!,
                                       method: .GET) { result in
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IBitBucketAPIPullRequest].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching open PRs for repository \(workspace)/\(repo)", error)
                    completion(nil)
                }
            }
        }

    public func fetchPullRequest(
        owner: String,
        repository: String,
        prNumber: String,
        completion: @escaping (IBitBucketAPIPullRequest?) -> Void
    ) {
        let path = "/repositories/\(owner)/\(repository)/pullrequests/\(prNumber)"

        AuroraNetworking()
            .request(baseURL: bitbucketURL,
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IBitBucketAPIPullRequest.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR for \(owner)/\(repository)/pullrequests/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    public func fetchPullRequestComments(
        owner: String,
        repository: String,
        prNumber: String,
        completion: @escaping ([IAPIComment]?) -> Void
    ) {
        let path = "/repositories/\(owner)/\(repository)/pullrequests/\(prNumber)/comments"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIComment].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR comments for \(owner)/\(repository)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

}
