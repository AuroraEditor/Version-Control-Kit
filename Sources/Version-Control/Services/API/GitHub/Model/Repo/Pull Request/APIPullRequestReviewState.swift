//
//  APIPullRequestReviewState.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

public enum APIPullRequestReviewState: String, Codable {
    case approved = "APPROVED"
    case dismissed = "DISMISSED"
    case pending = "PENDING"
    case commented = "COMMENTED"
    case changesRequested = "CHANGES_REQUESTED"
}
