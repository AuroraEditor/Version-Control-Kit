//
//  NetworkingError.swift
//
//
//  Created by Nanashi Li on 2023/11/26.
//

import Foundation

public enum NetworkingError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(statusCode: Int, data: Data)
    case encodingFailed(Error)
}
