//
//  IAPIRefCheckRun.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIRefCheckRun: Codable {
    let id: Int
    let url: String
    let status: APICheckStatus
    let conclusion: APICheckConclusion?
    let name: String
    let check_suite: IAPIRefCheckRunCheckSuite
    let app: IAPIRefCheckRunApp
    let completed_at: String
    let started_at: String
    let html_url: String
    let pull_requests: [IAPIPullRequest]
}
