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

    public func request(
        baseURL: String? = AuroraNetworkingConstants.GithubURL,
        path: String,
        headers: [String: String]? = nil,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completionHandler: @escaping (Result<(Data, [AnyHashable: Any]), Error>) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        print("Request initiated from file: \(file), line: \(line), function: \(function)")
        guard let baseURL = baseURL, let fullURL = URL(string: baseURL + path) else {
            print("Invalid URL: \(baseURL ?? "")\(path)")
            completionHandler(.failure(NetworkingError.invalidURL))
            return
        }
        print("Full URL: \(fullURL.absoluteString)")

        var request = createRequest(url: fullURL, headers: headers)
        request.httpMethod = method.rawValue
        print("HTTP Method: \(method.rawValue)")

        if let params = parameters, [.POST, .PUT, .PATCH].contains(method) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params)
                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                print("Request Parameters: \(params)")
            } catch {
                print("Encoding parameters failed: \(error)")
                completionHandler(.failure(NetworkingError.encodingFailed(error)))
                return
            }
        }

        exec(
            with: request,
            completionHandler: completionHandler,
            file: file,
            line: line,
            function: function
        )
    }

    private func exec(
        with request: URLRequest,
        completionHandler: @escaping (Result<(Data, [AnyHashable: Any]), Error>) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        // Create a URLSession
        let session: URLSession = URLSession.shared

        if let cookieData = AuroraNetworking.cookies {
            session.configuration.httpCookieStorage?.setCookies(
                cookieData,
                for: request.url,
                mainDocumentURL: nil
            )
        }

        // Start our data task
        session.dataTask(with: request) { [weak self] (sitedata, response, taskError) in
            guard let sitedata = sitedata else {
                completionHandler(.failure(taskError ?? NetworkingError.customError(message: "Unknown error occurred")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200, 201:
                    let headers = httpResponse.allHeaderFields
                    completionHandler(.success((sitedata, headers)))
                    print("[\(function)] HTTP OK")
                default:
                    let error = NetworkingError.customError(message: String(decoding: sitedata, as: UTF8.self))
                    completionHandler(.failure(error))
                }
            } else {
                let error = NetworkingError.customError(message: "Invalid response received")
                completionHandler(.failure(error))
            }
        }.resume()
    }

    private func processResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<(Data, [AnyHashable: Any]), Error> {
        if let error = error {
            print("Request failed with error: \(error)")
            return .failure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response received")
            return .failure(NetworkingError.invalidResponse)
        }

        guard let sitedata = data else {
            print("No data received")
            return .failure(NetworkingError.noData)
        }

        AuroraNetworking.fullResponse = String(data: sitedata, encoding: .utf8)
        let headers = httpResponse.allHeaderFields
        print("Response Status Code: \(httpResponse.statusCode)")
        print("Response Headers: \(headers)")
        print("Response Data: \(AuroraNetworking.fullResponse ?? "No response data")")

        switch httpResponse.statusCode {
        case 200, 201:
            return .success((sitedata, headers))
        default:
            print("Server error with status code: \(httpResponse.statusCode)")
            return .failure(NetworkingError.serverError(statusCode: httpResponse.statusCode, data: sitedata))
        }
    }

    private func createRequest(url: URL, headers: [String: String]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        print("Request Headers: \(headers ?? [:])")
        return request
    }
}
