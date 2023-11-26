//
//  IAPIRepoRuleMetadataParameters.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 Metadata parameters for a repo rule metadata rule.
 */
struct IAPIRepoRuleMetadataParameters: Codable {
    /**
     User-supplied name/description of the rule.
     */
    let name: String
    
    /**
     Whether the operator is negated. For example, if `true`
     and `operator` is `starts_with`, then the rule
     will be negated to 'does not start with'.
     */
    let negate: Bool
    
    /**
     The pattern to match against. If the operator is 'regex', then
     this is a regex string match. Otherwise, it is a raw string match
     of the type specified by `operator` with no additional parsing.
     */
    let pattern: String
    
    /**
     The type of match to use for the pattern. For example, `starts_with`
     means `pattern` must be at the start of the string.
     */
    let operatorType: APIRepoRuleMetadataOperator
}
