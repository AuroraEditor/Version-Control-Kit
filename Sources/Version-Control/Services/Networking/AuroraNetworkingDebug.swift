//
//  AuroraNetworkingDebug.swift
//
//
//  Created by Nanashi Li on 2023/11/26.
//

import Foundation

extension AuroraNetworking {
    /// Return the full networkRequestResponse
    /// - Returns: the full networkRequestResponse
    public func networkRequestResponse() -> String? {
        return AuroraNetworking.fullResponse
    }

    func networkLog(request: URLRequest?,
                    session: URLSession?,
                    response: URLResponse?,
                    data: Data?,
                    file: String = #file,
                    line: Int = #line,
                    function: String = #function) {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 else {
            return
        }

#if DEBUG
        print("Network debug start")
        networkLogRequest(request)
        networkLogResponse(httpResponse)
        networkLogData(data)
        print("End of network debug\n")
#endif
    }

    private func networkLogRequest(_ request: URLRequest?) {
        guard let request = request else { return }

        print("URLRequest:")
        if let httpMethod = request.httpMethod, let url = request.url {
            print("  \(httpMethod) \(url)")
        }

        print("\n  Headers:")
        if let allHTTPHeaderFields = request.allHTTPHeaderFields {
            for (header, content) in allHTTPHeaderFields {
                print("    \(header): \(content)")
            }
        }

        print("\n  Body:")
        if let httpBody = request.httpBody, let body = String(data: httpBody, encoding: .utf8) {
            print("    \(body)")
        }
        print("\n")
    }

    private func networkLogResponse(_ response: HTTPURLResponse) {
        print("HTTPURLResponse:")
        print("  HTTP \(response.statusCode)")

        for (header, content) in response.allHeaderFields {
            print("    \(header): \(content)")
        }
    }

    private func networkLogData(_ data: Data?) {
        guard let data = data, let stringData = String(data: data, encoding: .utf8) else { return }

        print("\n  Body:")
        for line in stringData.split(separator: "\n") {
            print("    \(line)")
        }

        do {
            print("\n  Decoded JSON:")
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                for (key, value) in jsonObject {
                    print("    \(key): \(value)")
                }
            }
        } catch {
            print("JSON Decoding Error: \(error.localizedDescription)")
        }
    }

    private func handleNetworkError(data: Data?) -> String {
        guard let data = data, let errorData = String(data: data, encoding: .utf8) else { return "Unknown error occurred." }

        return errorData
            .split(separator: "\n")
            .map(String.init)
            .joined(separator: " ")
    }
}
