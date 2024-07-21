//
//  GitHubAPI.swift
//
//
//  Created by Nanashi LI on 2023/09/24.
//

import Foundation

public struct GitHubAPI { // swiftlint:disable:this type_body_length

    public init() {}

    /// Creates a new GitHub repository.
    ///
    /// This function allows the user to create a new GitHub repository either under their 
    /// own account or within an organization. It provides parameters for specifying the repository's name,
    /// description, and whether it should be private or public.
    ///
    /// - Parameters:
    ///   - org: An optional `IAPIOrganization` object representing the organization where the repository \
    ///          should be created. Pass `nil` to create the repository under the authenticated user's account.
    ///   - name: The name of the new repository.
    ///   - description: A brief description of the repository.
    ///   - isPrivate: A Boolean flag indicating whether the repository should be private (`true`) or public (`false`).
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides a `Result` object with either an `IAPIFullRepository` \
    ///                 containing information about the created repository (if successful) \
    ///                 or an `Error` (if the request fails).
    ///
    /// - Example:
    ///   ```swift
    ///   createRepository(
    ///       org: organization,
    ///       name: "my-new-repo",
    ///       description: "A new repository",
    ///       isPrivate: true
    ///   ) { result in
    ///       switch result {
    ///       case .success(let repository):
    ///           print("Repository Created:")
    ///           print("- Name: \(repository.name)")
    ///           print("- Description: \(repository.description)")
    ///           print("- Private: \(repository.isPrivate)")
    ///           // Handle the newly created repository.
    ///       case .failure(let error):
    ///           print("Failed to create repository:", error.localizedDescription)
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user is authenticated and has the necessary permissions to create repositories.\
    ///              If creating a repository within an organization, \
    ///              the user should have appropriate organization permissions.
    ///
    /// - SeeAlso: https://docs.github.com/en/rest/reference/repos#create-a-repository-for-the-authenticated-user
    ///
    /// - SeeAlso: https://docs.github.com/en/rest/reference/repos#create-an-organization-repository
    ///
    /// - SeeAlso: https://docs.github.com/en/get-started/quickstart/create-a-repo
    func createRepository(
        org: IAPIOrganization?,
        name: String,
        description: String,
        isPrivate: Bool,
        completion: @escaping (IAPIFullRepository?) -> Void
    ) {
        let path = org != nil ? "orgs/\(org!.login)/repos" : "user/repos"
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
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIFullRepository.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                    }
                case .failure(let error):
                    // swiftlint:disable:next line_length
                    print("Unable to publish repository. Please check if you have an internet connection and try again.", error)
                    completion(nil)
                }
            })
    }

    /// Fetches branch protection information to determine if a user can push to a given branch.
    ///
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - name: The name of the repository.
    ///   - branch: The name of the branch to check.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an `IAPIPushControl` object representing the branch protection settings, \
    ///                 or `nil` if the request fails.
    ///
    /// - Returns: A `IAPIPushControl` object representing the branch protection settings.
    ///
    /// - Note: If the request fails, the function returns default values assuming full access for the user.
    ///
    /// - Example:
    ///   ```swift
    ///   fetchPushControl(owner: "octocat", name: "my-repo", branch: "main") { pushControl in
    ///       if let pushControl = pushControl {
    ///           if pushControl.isEnabled {
    ///               print("Branch protection is enabled.")
    ///               if pushControl.isUserAllowedToPush {
    ///                   print("The user is allowed to push to the branch.")
    ///               } else {
    ///                   print("The user is not allowed to push to the branch.")
    ///               }
    ///           } else {
    ///               print("Branch protection is not enabled.")
    ///           }
    ///       } else {
    ///           print("Failed to fetch branch protection information.")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user has the necessary permissions to fetch branch protection settings \
    ///              for the repository.
    ///
    /// - SeeAlso: https://docs.github.com/en/rest/reference/repos#get-branch-protection
    func fetchPushControl(
        owner: String,
        name: String,
        branch: String,
        completion: @escaping (IAPIPushControl?) -> Void
    ) {
        guard let branchName = branch.urlEncode() else {
            return
        }

        let path = "repos/\(owner)/\(name)/branches/\(branchName)/push_control"

        let headers: [String: String] = [
            "Accept": "application/vnd.github.phandalin-preview"
        ]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     headers: headers,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIPushControl.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchPushControl] unable to check if branch is potentially pushable", error)
                    completion(nil)
                }
            })
    }

    /// Fetches protected branches for the given repository.
    ///
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - name: The name of the repository.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an array of protected branches (`[IAPIBranch]`), or `nil` if the request fails.
    ///
    /// - Returns: A promise of an array of protected branches (`IAPIBranch`).
    ///
    /// - Example:
    ///   ```swift
    ///   fetchProtectedBranches(owner: "octocat", name: "my-repo") { protectedBranches in
    ///       if let protectedBranches = protectedBranches {
    ///           for branch in protectedBranches {
    ///               print("Branch Name: \(branch.name)")
    ///           }
    ///       } else {
    ///           print("Failed to fetch protected branches.")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user has the necessary permissions to fetch protected branches for the repository.
    ///
    /// - SeeAlso: [GitHub API Documentation](https://docs.github.com/en/rest/reference/repos#list-branches)
    public func fetchProtectedBranches(
        owner: String,
        name: String,
        completion: @escaping ([IAPIBranch]?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/branches?protected=true"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, headers)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIBranch].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchProtectedBranches] unable to list protected branches", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Repository Info

    /// Fetches mentionable users for the given repository.
    ///
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - name: The name of the repository.
    ///   - etag: An optional ETag header value to check for changes since the last request.
    ///   - completion: A closure that is called upon completion of the API request.
    ///                 It provides an `IAPIMentionableResponse` object containing the ETag
    ///                 and an array of mentionable users, or `nil` if the request fails.
    ///
    /// - Example:
    ///   ```swift
    ///   fetchMentionables(owner: "octocat", name: "my-repo", etag: nil) { response in
    ///       if let response = response {
    ///           print("ETag: \(response.etag ?? "No ETag")")
    ///           for user in response.users {
    ///               print("User: \(user.login)")
    ///           }
    ///       } else {
    ///           print("Failed to fetch mentionable users.")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: The custom `Accept` header is required for the `mentionables` endpoint.
    public func fetchMentionables(
        owner: String,
        name: String,
        etag: String?
    ) throws -> IAPIMentionableResponse? {
        let path = "repos/\(owner)/\(name)/mentionables/users"

        // Notice: This custom `Accept` is required for the `mentionables` endpoint.
        var headers = [
            "Accept": "application/vnd.github.jerry-maguire-preview"
        ]

        if let etag = etag {
            headers["If-None-Match"] = etag
        }

        var result: IAPIMentionableResponse?
        var requestError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        AuroraNetworking().request(
            path: path,
            headers: headers,
            method: .GET,
            parameters: nil,
            completionHandler: { responseResult in
                switch responseResult {
                case .success(let (data, headers)):
                    print(data)
                    let decoder = JSONDecoder()
                    if let mentionables = try? decoder.decode([IAPIMentionableUser].self, from: data) {
                        print(mentionables)
                        result = IAPIMentionableResponse(
                            etag: headers["Etag"] as? String,
                            users: mentionables
                        )
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        requestError = NSError(domain: "DecodeError", code: 0, userInfo: nil)
                    }
                case .failure(let error):
                    print("Failed to fetch mentionables for \(owner)/\(name)", error)
                    requestError = error
                }
                semaphore.signal()
            }
        )

        // Wait for the network request to complete
        _ = semaphore.wait(timeout: .distantFuture)

        if let error = requestError {
            throw error
        }
        return result
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
        since: Date?,
        completion: @escaping ([IAPIIssue]?) -> Void
    ) {
        var params: [String: String] = ["state": state.rawValue]

        if let sinceDate = since {
            params["since"] = Date().toGitHubIsoDateString(sinceDate)
        }

        let path = "repos/\(owner)/\(name)/issues".urlEncode(params)

        AuroraNetworking()
            .request(baseURL: "",
                     path: path!,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
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

    /**
     Fetches all comments from a given issue.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - issueNumber: The number of the issue for which comments are to be fetched.
     
     - Returns: An array of `IAPIComment` objects representing the comments on the issue.
     */
    public func fetchIssueComments(
        owner: String,
        name: String,
        issueNumber: String,
        completion: @escaping ([IAPIComment]?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/issues/\(issueNumber)/comments"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIComment].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching issue comments for \(owner)/\(name)/issues/\(issueNumber)", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Repository Pull Requests

    /**
     Fetches all open pull requests in the given repository.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     
     - Returns: A `Promise` that resolves to an array of `IAPIPullRequest` or an error.
     */
    public func fetchAllOpenPullRequests(
        owner: String,
        name: String,
        completion: @escaping ([IAPIPullRequest]?) -> Void) {
            let path = "repos/\(owner)/\(name)/pulls".urlEncode(["state": "open"])

            AuroraNetworking()
                .request(baseURL: "",
                         path: path!,
                         method: .GET,
                         parameters: nil,
                         completionHandler: { result in
                    switch result {
                    case .success(let (data, _)):
                        let decoder = JSONDecoder()
                        if let fetchedRuleset = try? decoder.decode([IAPIPullRequest].self, from: data) {
                            completion(fetchedRuleset)
                        } else {
                            print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                            completion(nil)
                        }
                    case .failure(let error):
                        print("Failed fetching open PRs for repository \(owner)/\(name)", error)
                        completion(nil)
                    }
                })
        }

    /**
     Fetch a single pull request in the given repository.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - prNumber: The number of the pull request.
     
     - Returns: An `IAPIPullRequest` object representing the requested pull request.
     - Throws: An error if the request fails.
     */
    public func fetchPullRequest(
        owner: String,
        name: String,
        prNumber: String,
        completion: @escaping (IAPIPullRequest?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/pulls/\(prNumber)"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIPullRequest.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR for \(owner)/\(name)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    /**
     Fetch a single pull request review in the given repository.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - prNumber: The number of the pull request.
     - reviewId: The ID of the review to fetch.
     
     - Returns: An `IAPIPullRequestReview` object representing the requested pull request review, or `nil` if not found.
     */
    public func fetchPullRequestReview(
        owner: String,
        name: String,
        prNumber: String,
        reviewId: String,
        completion: @escaping (IAPIPullRequestReview?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/pulls/\(prNumber)/reviews/\(reviewId)"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIPullRequestReview.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR review \(reviewId) for \(owner)/\(name)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    /**
     Fetches all reviews from a given pull request.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - prNumber: The number of the pull request for which reviews are to be fetched.
     
     - Returns: An array of `IAPIPullRequestReview` objects representing the reviews on the pull request.
     */
    public func fetchPullRequestReviews(
        owner: String,
        name: String,
        prNumber: String,
        completion: @escaping ([IAPIPullRequestReview]?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/pulls/\(prNumber)/reviews"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIPullRequestReview].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR reviews for \(owner)/\(name)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    /**
     Fetches all review comments from a given pull request review.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - prNumber: The number of the pull request for which review comments are to be fetched.
     - reviewId: The ID of the pull request review.
     
     - Returns: An array of `IAPIComment` objects representing the review comments on the pull request review.
     */
    public func fetchPullRequestReviewComments(
        owner: String,
        name: String,
        prNumber: String,
        reviewId: String,
        completion: @escaping ([IAPIComment]?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/pulls/\(prNumber)/reviews/\(reviewId)/comments"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIComment].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR review comments for \(owner)/\(name)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    /**
     Fetches all review comments from a given pull request.
     
     - Parameters:
     - owner: The owner of the repository.
     - name: The name of the repository.
     - prNumber: The number of the pull request for which comments are to be fetched.
     
     - Returns: An array of `IAPIComment` objects representing the review comments on the pull request.
     */
    public func fetchPullRequestComments(
        owner: String,
        name: String,
        prNumber: String,
        completion: @escaping ([IAPIComment]?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/pulls/\(prNumber)/comments"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPIComment].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed fetching PR comments for \(owner)/\(name)/pulls/\(prNumber)", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Repository Rules

    /// Fetches repository rules for a specific branch in a GitHub repository.
    ///
    /// This function retrieves repository rules associated with a specific branch in a GitHub repository.
    /// Repository rules are used to define code analysis and linting rules that apply to the repository's
    /// codebase on a per-branch basis. It allows you to fetch a list of rules applicable to a particular branch.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - branch: The name of the branch for which to fetch repository rules.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional array of `IAPIRepoRule` objects that contain information \
    ///                 about repository rules for the specified branch. \
    ///                 If the request is successful and data can be decoded, the closure receives the array; \
    ///                 otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for fetching rules that apply to a specific branch of a GitHub repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let branchName = "main"
    ///
    ///   fetchRepoRulesForBranch(owner: owner, name: repoName, branch: branchName) { repoRules in
    ///       if let fetchedRules = repoRules {
    ///           print("Fetched repository rules for branch \(branchName):")
    ///           for rule in fetchedRules {
    ///               print("- Rule ID: \(rule.id), Name: \(rule.name), Status: \(rule.status)")
    ///           }
    ///           // Handle the array of repository rules.
    ///       } else {
    ///           print("Failed to fetch repository rules for branch \(branchName).")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access repository rules for the \
    ///              specified branch within the GitHub repository.
    public func fetchRepoRulesForBranch(
        owner: String,
        name: String,
        branch: String,
        completion: @escaping ([IAPIRepoRule]?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/rules/branches/\(branch)"

        AuroraNetworking()
            .request(path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    do {
                        // Try decoding the data and catch any potential errors
                        let fetchedRuleset = try decoder.decode([IAPIRepoRule].self, from: data)
                        completion(fetchedRuleset)
                    } catch {
                        // Print the error for debugging purposes
                        print("Error: Unable to decode \(error)")
                        print("Data: \(String(data: data, encoding: .utf8) ?? "")")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchRepoRulesForBranch] unable to fetch repo rules for branch: \(branch) | \(path)", error)
                    completion(nil)
                }
            })
    }

    /// Fetches all repository rulesets from a GitHub repository.
    ///
    /// This function retrieves all repository rulesets associated with a GitHub repository.
    /// Repository rulesets are used to define code analysis and linting rules that apply to the repository.
    /// It allows you to fetch a list of all rulesets available in the repository.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional array of `IAPISlimRepoRuleset` objects that contain information \
    ///                 about all fetched repository rulesets. If the request is successful and data can be decoded, \
    ///                 the closure receives the array; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for fetching a list of all repository rulesets within a GitHub repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///
    ///   fetchAllRepoRulesets(owner: owner, name: repoName) { repoRulesets in
    ///       if let fetchedRulesets = repoRulesets {
    ///           print("Fetched a list of repository rulesets:")
    ///           for ruleset in fetchedRulesets {
    ///               print("- Ruleset ID: \(ruleset.id), Name: \(ruleset.name)")
    ///           }
    ///           // Handle the array of repository rulesets.
    ///       } else {
    ///           print("Failed to fetch repository rulesets.")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access \
    ///              repository rulesets within the GitHub repository.
    func fetchAllRepoRulesets(
        owner: String,
        name: String,
        completion: @escaping ([IAPISlimRepoRuleset]?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/rulesets"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode([IAPISlimRepoRuleset].self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchAllRepoRulesets] unable to fetch all repo rulesets | \(path)", error)
                    completion(nil)
                }
            })
    }

    /// Fetches a repository ruleset by its ID from a GitHub repository.
    ///
    /// This function retrieves a repository ruleset by its unique identifier (`id`) from a GitHub repository.
    /// Repository rulesets are used to define code analysis and linting rules that apply to the repository.
    /// This function allows you to fetch the details of a specific ruleset based on its ID.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - id: The unique identifier of the repository ruleset to fetch.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional `IAPIRepoRuleset` object that contains information about \
    ///                 the fetched repository ruleset. If the request is successful and data can be decoded, \
    ///                 the closure receives the `IAPIRepoRuleset` object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for fetching details about a specific repository ruleset within \
    ///         a GitHub repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let rulesetId = 12345
    ///
    ///   fetchRepoRuleset(owner: owner, name: repoName, id: rulesetId) { repoRuleset in
    ///       if let fetchedRuleset = repoRuleset {
    ///           print("Fetched details for repository ruleset with ID \(rulesetId)")
    ///           // Handle the repository ruleset data.
    ///       } else {
    ///           print("Failed to fetch repository ruleset with ID \(rulesetId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access repository \
    ///              rulesets within the GitHub repository.
    func fetchRepoRuleset(
        owner: String,
        name: String,
        id: Int,
        completion: @escaping (IAPIRepoRuleset?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/rulesets/\(id)"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIRepoRuleset.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchRepoRuleset] unable to fetch repo ruleset for ID: \(id) | \(path)", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Workflows

    /// Fetches GitHub Actions check runs associated with a specific Git reference in a repository.
    ///
    /// This function retrieves information about the GitHub Actions check runs that are associated with 
    /// a specific Git reference in a GitHub repository. 
    /// It is typically used to obtain check run details for a particular branch or commit.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - ref: The Git reference (e.g., branch or commit SHA) for which you want to fetch associated check runs.
    ///   - reloadCache: A flag indicating whether to reload cached data. Set to `true` to bypass \
    ///                  the cache and fetch fresh data.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional `IAPIRefCheckRuns` object that contains information about \
    ///                 the check runs associated with the specified Git reference. \
    ///                 If the request is successful and data can be decoded, the closure receives \
    ///                 the `IAPIRefCheckRuns` object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining details about check runs related to a \
    ///         specific Git reference, such as branch or commit.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let branchName = "feature-branch"
    ///
    ///   fetchRefCheckRuns(owner: owner, name: repoName, ref: branchName) { checkRuns in
    ///       if let runsData = checkRuns {
    ///           print("Fetched details for check runs associated with branch \(branchName)")
    ///           // Handle the check runs data.
    ///       } else {
    ///           print("Failed to fetch check runs for branch \(branchName)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access check\
    ///              run details for the GitHub repository.
    func fetchRefCheckRuns(
        owner: String,
        name: String,
        ref: String,
        completion: @escaping (IAPIRefCheckRuns?) -> Void
    ) {
        let safeRef = ref.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

        let path = "repos/\(owner)/\(name)/commits/\(safeRef)/check-runs?per_page=100"

        let headers = [
            "Accept": "application/vnd.github.antiope-preview+json"
        ]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     headers: headers,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let runs = try? decoder.decode(IAPIRefCheckRuns.self, from: data) {
                        completion(runs)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed parsing check runs for ref \(ref) (\(owner)/\(name))", error)
                    completion(nil)
                }
            })
    }

    /// Fetches GitHub Actions workflow runs associated with a specific branch name in a repository's pull requests.
    ///
    /// This function retrieves information about the GitHub Actions workflow runs that correspond 
    /// to a particular branch name in pull requests of a GitHub repository. 
    /// It is typically used to obtain workflow run details triggered by pull request events.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - branchName: The name of the branch for which you want to fetch associated workflow runs in pull requests.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional `IAPIWorkflowRuns` object that contains information about \
    ///                 the workflow runs associated with the specified branch in pull requests. \
    ///                 If the request is successful and data can be decoded, the closure receives \
    ///                 the `IAPIWorkflowRuns` object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining details about workflow runs triggered \
    ///         by events related to a specific branch in pull requests.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let branchName = "feature-branch"
    ///
    ///   fetchPRWorkflowRunsByBranchName(owner: owner, name: repoName, branchName: branchName) { workflowRuns in
    ///       if let runsData = workflowRuns {
    ///           print("Fetched details for workflow runs associated with branch \(branchName) in pull requests")
    ///           // Handle the workflow runs data.
    ///       } else {
    ///           print("Failed to fetch workflow runs for branch \(branchName) in pull requests")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access workflow run details \
    ///              for the GitHub repository.
    ///
    /// - SeeAlso: https://docs.github.com/en/rest/reference/actions#list-workflow-runs-for-a-repository
    ///
    /// - SeeAlso: https://docs.github.com/en/rest/reference/actions#workflow-runs
    func fetchPRWorkflowRunsByBranchName(
        owner: String,
        name: String,
        branchName: String,
        completion: @escaping (IAPIWorkflowRuns?) -> Void
    ) {
        // swiftlint:disable:next line_length
        let path = "repos/\(owner)/\(name)/actions/runs?event=pull_request&branch=\(branchName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"

        let headers = ["Accept": "application/vnd.github.antiope-preview+json"]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     headers: headers,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let runs = try? decoder.decode(IAPIWorkflowRuns.self, from: data) {
                        completion(runs)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed parsing workflow runs for \(branchName) (\(owner)/\(name))", error)
                    completion(nil)
                }
            })
    }

    /// Fetches the GitHub Actions workflow run associated with a specific check suite ID in a repository.
    ///
    /// This function retrieves information about the GitHub Actions workflow run that corresponds 
    /// to a particular check suite ID in a GitHub repository. 
    /// It is typically used to obtain workflow run details triggered by a pull request or a push event.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - checkSuiteId: The identifier of the check suite for which you want to fetch the associated workflow run.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional `IAPIWorkflowRun` object that contains information about \
    ///                 the workflow run associated with the check suite. If the request is successful \
    ///                 and data can be decoded, the closure receives the `IAPIWorkflowRun` object; \
    ///                 otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining details about the workflow run triggered by a \
    ///         specific check suite ID, which is often associated with pull requests and \
    ///         continuous integration (CI) workflows.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let checkSuiteId = 12345
    ///
    ///   fetchWorkflowRunByCheckSuiteId(owner: owner, name: repoName, checkSuiteId: checkSuiteId) { workflowRun in
    ///       if let runData = workflowRun {
    ///           print("Fetched details for workflow run associated with check suite \(checkSuiteId)")
    ///           // Handle the workflow run data.
    ///       } else {
    ///           print("Failed to fetch workflow run for check suite \(checkSuiteId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access workflow run details for \
    ///              the GitHub repository.
    func fetchWorkflowRunByCheckSuiteId(
        owner: String,
        name: String,
        checkSuiteId: Int,
        completion: @escaping (IAPIWorkflowRun?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/actions/runs?event=pull_request&check_suite_id=\(checkSuiteId)"

        let headers = ["Accept": "application/vnd.github.antiope-preview+json"]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     headers: headers,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let runs = try? decoder.decode(IAPIWorkflowRun.self, from: data) {
                        completion(runs)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed parsing workflow runs for \(checkSuiteId) (\(owner)/\(name))", error)
                    completion(nil)
                }
            })
    }

    /// Fetches the jobs associated with a specific GitHub Actions workflow run for a repository.
    ///
    /// This function retrieves information about the jobs that were part of a particular workflow run 
    /// in a GitHub Actions workflow for a specific repository.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - workflowRunId: The identifier of the GitHub Actions workflow run for which you want to fetch jobs.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an optional `IAPIWorkflowJobs` object that contains information about \
    ///                 the jobs in the workflow run. If the request is successful and data can be decoded, \
    ///                 the closure receives the `IAPIWorkflowJobs` object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining details about the jobs executed as part of a \
    ///         specific workflow run.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let workflowRunId = 12345
    ///
    ///   fetchWorkflowRunJobs(owner: owner, name: repoName, workflowRunId: workflowRunId) { jobs in
    ///       if let jobsData = jobs {
    ///           print("Fetched \(jobsData.jobs.count) jobs for workflow run \(workflowRunId)")
    ///           // Handle the jobs data.
    ///       } else {
    ///           print("Failed to fetch jobs for workflow run \(workflowRunId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access workflow run details \
    ///              for the GitHub repository.
    func fetchWorkflowRunJobs(
        owner: String,
        name: String,
        workflowRunId: Int,
        completion: @escaping (IAPIWorkflowJobs?) -> Void
    ) {
        let path = "repos/\(owner)/\(name)/actions/runs/\(workflowRunId)/jobs"

        let headers = ["Accept": "application/vnd.github.antiope-preview+json"]

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     headers: headers,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let runs = try? decoder.decode(IAPIWorkflowJobs.self, from: data) {
                        completion(runs)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed parsing workflow jobs (\(owner)/\(name)) workflow run: \(workflowRunId)", error)
                    completion(nil)
                }
            })
    }

    /// Rerequests a GitHub check suite for a repository.
    ///
    /// This function triggers the rerequest of a specific GitHub check suite for a repository.
    /// It uses the GitHub API to make the request.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - checkSuiteId: The identifier of the GitHub check suite to rerequest.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides a Boolean value indicating whether the rerequest of the check suite \
    ///                 was successful (`true`) or not (`false`).
    ///
    /// - Note: This function is useful for manually triggering the reevaluation of checks and statuses\
    ///         in a check suite.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let checkSuiteId = 12345
    ///
    ///   rerequestCheckSuite(owner: owner, name: repoName, checkSuiteId: checkSuiteId) { success in
    ///       if success {
    ///           print("Successfully triggered rerequest for check suite ID \(checkSuiteId)")
    ///           // Handle the success case.
    ///       } else {
    ///           print("Failed to trigger rerequest for check suite ID \(checkSuiteId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access \
    ///              the GitHub repository and trigger check suite rerequests.
    public func rerequestCheckSuite(
        owner: String,
        name: String,
        checkSuiteId: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/check-suites/\(checkSuiteId)/rerequest"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .POST,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("Failed retry check suite id \(checkSuiteId) (\(owner)/\(name))", error)
                    completion(false)
                }
            })
    }

    /// Reruns all failed jobs in a GitHub Actions workflow run for a repository.
    ///
    /// This function triggers the rerun of all failed jobs in a specific GitHub Actions workflow
    /// run for a repository.
    /// It uses the GitHub API to make the request.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - workflowRunId: The identifier of the GitHub Actions workflow run for which to rerun failed jobs.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides a Boolean value indicating whether the rerun of failed jobs was \
    ///                 successful (`true`) or not (`false`).
    ///
    /// - Note: This function is useful for automatically rerunning jobs that failed in a workflow run \
    ///         to address issues or retest specific changes.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let workflowRunId = 7890
    ///
    ///   rerunFailedJobs(owner: owner, name: repoName, workflowRunId: workflowRunId) { success in
    ///       if success {
    ///           print("Successfully triggered rerun of failed jobs for workflow run ID \(workflowRunId)")
    ///           // Handle the success case.
    ///       } else {
    ///           print("Failed to trigger rerun of failed jobs for workflow run ID \(workflowRunId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions to access \
    ///              the GitHub repository and trigger job reruns.
    public func rerunFailedJobs(
        owner: String,
        name: String,
        workflowRunId: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/actions/runs/\(workflowRunId)/rerun-failed-jobs"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .POST,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("Failed to rerun failed workflow jobs for (\(owner)/\(name)): \(workflowRunId)", error)
                    completion(false)
                }
            })
    }

    /// Reruns a specific GitHub Actions job for a repository.
    ///
    /// This function triggers the rerun of a GitHub Actions job for a specific repository.
    /// It uses the GitHub API to make the request.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - jobId: The identifier of the GitHub Actions job to rerun.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides a Boolean value indicating whether the job rerun \
    ///                 was successful (`true`) or not (`false`).
    ///
    /// - Note: GitHub Actions allows you to rerun specific jobs within a workflow to \
    ///         address issues or retest specific changes.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let jobId = 12345
    ///
    ///   rerunJob(owner: owner, name: repoName, jobId: jobId) { success in
    ///       if success {
    ///           print("Successfully triggered job rerun for job ID \(jobId)")
    ///           // Handle the success case.
    ///       } else {
    ///           print("Failed to trigger job rerun for job ID \(jobId)")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    public func rerunJob(
        owner: String,
        name: String,
        jobId: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/actions/jobs/\(jobId)/rerun"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .POST,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("Failed to rerun workflow job (\(owner)/\(name)): \(jobId)", error)
                    completion(false)
                }
            })
    }

    /// Fetches information about a specific GitHub check suite by its identifier.
    ///
    /// This function retrieves details about a GitHub check suite, including its status,
    /// associated pull request, and other relevant information. It uses the GitHub API to make the request.
    ///
    /// - Parameters:
    ///   - owner: The owner or organization name of the GitHub repository.
    ///   - name: The name of the GitHub repository.
    ///   - checkSuiteId: The identifier of the GitHub check suite to fetch.
    ///   - completion: A closure that is called upon completion of the API request. \
    ///                 It provides an `IAPICheckSuite` object representing the fetched check suite, \
    ///                 or `nil` if the fetch operation fails.
    ///
    /// - Note: The `IAPICheckSuite` structure represents the data model for a GitHub check suite.
    ///
    /// - Example:
    ///   ```swift
    ///   let owner = "octocat"
    ///   let repoName = "my-repo"
    ///   let checkSuiteId = 12345
    ///
    ///   fetchCheckSuite(owner: owner, name: repoName, checkSuiteId: checkSuiteId) { checkSuite in
    ///       if let checkSuite = checkSuite {
    ///           print("Fetched Check Suite:")
    ///           print("Status: \(checkSuite.status)")
    ///           print("Pull Request: \(checkSuite.pullRequestURL)")
    ///           // Handle the check suite data as needed.
    ///       } else {
    ///           print("Failed to fetch Check Suite with ID \(checkSuiteId)")
    ///           // Handle the fetch failure.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that you have the necessary permissions \
    ///              to access the GitHub repository and perform API requests.
    func fetchCheckSuite(
        owner: String,
        name: String,
        checkSuiteId: Int,
        completion: @escaping (IAPICheckSuite?) -> Void
    ) {
        let path = "/repos/\(owner)/\(name)/check-suites/\(checkSuiteId)"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let runs = try? decoder.decode(IAPICheckSuite.self, from: data) {
                        completion(runs)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("[fetchCheckSuite] Failed fetch check suite id \(checkSuiteId) (\(owner)/\(name))", error)
                    completion(nil)
                }
            })
    }

    // MARK: - Account Information

    /// Fetches the account information for the authenticated user.
    ///
    /// This function retrieves the account information for the currently authenticated user. 
    /// The account information typically includes details such as the user's username, avatar URL, 
    /// email, and other profile-related information.
    ///
    /// - Parameter completion: A closure that is called upon completion of the API request. \
    ///                         It provides an optional `IAPIFullIdentity` object that contains information \
    ///                         about the authenticated user's account. If the request is successful and data \
    ///                         can be decoded, the closure receives the object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining information about the authenticated user's GitHub account.
    ///
    /// - Example:
    ///   ```swift
    ///   fetchAccount { accountInfo in
    ///       if let userAccount = accountInfo {
    ///           print("Authenticated User's Account Information:")
    ///           print("- Username: \(userAccount.login)")
    ///           print("- Avatar URL: \(userAccount.avatarUrl)")
    ///           print("- Email: \(userAccount.email ?? "N/A")")
    ///           // Handle the user's account information.
    ///       } else {
    ///           print("Failed to fetch authenticated user's account information.")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user is authenticated and has the necessary permissions to \
    ///              access their account information.
    func fetchAccount(completion: @escaping (IAPIFullIdentity?) -> Void) {
        AuroraNetworking()
            .request(baseURL: "",
                     path: "user",
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIFullIdentity.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure(let error):
                    print("fetchAccount: failed with endpoint", error)
                    completion(nil)
                }
            })
    }

    /// Fetches the email addresses associated with the authenticated user's GitHub account.
    ///
    /// This function retrieves the email addresses associated with the authenticated user's GitHub account.
    /// Users can have one or more email addresses associated with their account, and this function 
    /// provides access to that information.
    ///
    /// - Parameter completion: A closure that is called upon completion of the API request. \
    ///                         It provides an optional `IAPIEmail` object that contains information about \
    ///                         the authenticated user's email addresses. \
    ///                         If the request is successful and data can be decoded, \
    ///                         the closure receives the object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining a list of email addresses associated with the \
    ///         authenticated user's GitHub account.
    ///
    /// - Example:
    ///   ```swift
    ///   fetchEmails { emailInfo in
    ///       if let emailData = emailInfo {
    ///           print("Authenticated User's Email Addresses:")
    ///           for email in emailData {
    ///               print("- \(email.email)")
    ///           }
    ///           // Handle the user's email addresses.
    ///       } else {
    ///           print("Failed to fetch authenticated user's email addresses.")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user is authenticated and has the necessary permissions \
    ///              to access their email addresses.
    ///
    func fetchEmails(completion: @escaping (IAPIEmail?) -> Void) {
        let path = "user/emails"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIEmail.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        print("Error: Unable to decode", String(data: data, encoding: .utf8) ?? "")
                        completion(nil)
                    }
                case .failure:
                    completion(nil)
                }
            })
    }

    /// Fetches a list of organizations that the authenticated user belongs to.
    ///
    /// This function retrieves a list of organizations that the authenticated user is a member of on GitHub.
    /// It can be used to obtain information about the organizations, such as their names and URLs.
    ///
    /// - Parameter completion: A closure that is called upon completion of the API request. \
    ///                         It provides an optional `IAPIOrganization` object that contains \
    ///                         information about the organizations that the authenticated user belongs to. \
    ///                         If the request is successful and data can be decoded, \
    ///                         the closure receives the object; otherwise, it receives `nil`.
    ///
    /// - Note: This function is useful for obtaining a list of organizations associated with \
    ///         the authenticated user's GitHub account.
    ///
    /// - Example:
    ///   ```swift
    ///   fetchOrgs { orgInfo in
    ///       if let orgData = orgInfo {
    ///           print("Organizations Belonging to the Authenticated User:")
    ///           for org in orgData {
    ///               print("- Name: \(org.login), URL: \(org.url)")
    ///           }
    ///           // Handle the list of organizations.
    ///       } else {
    ///           print("Failed to fetch organizations for the authenticated user.")
    ///           // Handle the failure case.
    ///       }
    ///   }
    ///   ```
    ///
    /// - Important: Ensure that the user is authenticated and has the necessary permissions to access their \
    ///              organization membership information.
    func fetchOrgs(completion: @escaping (IAPIOrganization?) -> Void) {
        let path = "user/orgs"

        AuroraNetworking()
            .request(baseURL: "",
                     path: path,
                     method: .GET,
                     parameters: nil,
                     completionHandler: { result in
                switch result {
                case .success(let (data, _)):
                    let decoder = JSONDecoder()
                    if let fetchedRuleset = try? decoder.decode(IAPIOrganization.self, from: data) {
                        completion(fetchedRuleset)
                    } else {
                        completion(nil)
                    }
                case .failure:
                    completion(nil)
                }
            })
    }
}
// swiftlint:disable:this file_length
