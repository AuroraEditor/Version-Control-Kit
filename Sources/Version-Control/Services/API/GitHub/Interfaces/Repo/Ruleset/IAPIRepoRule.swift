//
//  File.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

/**
 Repository rule information returned by the GitHub API.
 */
struct IAPIRepoRule: Codable {
    /**
     The ID of the ruleset this rule is configured in.
     */
    let ruleset_id: Int
    
    /**
     The type of the rule.
     */
    let type: APIRepoRuleType
    
    /**
     The parameters that apply to the rule if it is a metadata rule.
     Other rule types may have parameters, but they are not used in
     this app so they are ignored. Do not attempt to use this field
     unless you know `type` matches a metadata rule type.
     */
    let parameters: IAPIRepoRuleMetadataParameters?
}
