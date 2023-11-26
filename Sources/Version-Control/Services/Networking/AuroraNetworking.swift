//
//  AuroraNetworking.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

public class AuroraNetworking {
    static let shared = AuroraNetworking()
    static var cookies: [HTTPCookie]? = []
    static var fullResponse: String? = ""
    static let group: DispatchGroup = .init()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Combine the overloaded `request` methods into one with optional parameters
    public func request(
        baseURL: String? = AuroraNetworkingConstants.GithubURL,
        path: String,
        headers: [String: String]? = nil,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completionHandler: @escaping (Result<Data, Error>) -> Void,
        file: String = #file, line: Int = #line, function: String = #function
    ) {
        guard let baseURL = baseURL, let fullURL = URL(string: baseURL + path) else {
            completionHandler(.failure(NetworkingError.invalidURL))
            return
        }

        var request = createRequest(url: fullURL, headers: headers)
        request.httpMethod = method.rawValue

        // Serialize parameters as JSON for POST, PUT, and PATCH requests
        if let params = parameters, [.POST, .PUT, .PATCH].contains(method) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params)
                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                completionHandler(.failure(NetworkingError.encodingFailed(error)))
                return
            }
        }

        exec(request: request, completionHandler: completionHandler, file: file, line: line, function: function)
    }

    private func exec(
        request: URLRequest,
        completionHandler: @escaping (Result<Data, Error>) -> Void,
        file: String,
        line: Int,
        function: String
    ) {
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            let result = self.processResponse(data: data, response: response, error: error)
            completionHandler(result)
        }.resume()
    }

    private func processResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, Error> {
        if let error = error {
            return .failure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(NetworkingError.invalidResponse)
        }

        guard let sitedata = data else {
            return .failure(NetworkingError.noData)
        }

        AuroraNetworking.fullResponse = String(data: sitedata, encoding: .utf8)

        switch httpResponse.statusCode {
        case 200, 201:
            return .success(sitedata)
        default:
            return .failure(NetworkingError.serverError(statusCode: httpResponse.statusCode, data: sitedata))
        }
    }

    private func createRequest(url: URL, headers: [String: String]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
