//
//  IBitbucketRendered.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

struct IBitbucketRendered {
    var description: IBitbucketRenderedBody
}

struct IBitbucketRenderedBody: Codable {
    var raw: String
    var markup: String
    var html: String
}
