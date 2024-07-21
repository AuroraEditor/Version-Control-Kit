//
//  FiAPIRefStatele.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

// The combined state of a ref.
enum APIRefState: String, Codable {
    case failure
    case pending
    case success
    case error
}
