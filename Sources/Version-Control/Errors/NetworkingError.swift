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
    case customError(message: String)

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .noData:
            return "No data was received from the server."
        case .invalidResponse:
            return "The response received from the server was invalid."
        case .serverError(let statusCode, let data):
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
            return "Server error with status code \(statusCode): \(errorMessage)"
        case .encodingFailed(let error):
            return "Failed to encode parameters: \(error.localizedDescription)"
        case .customError(let message):
            return message
        }
    }
}
