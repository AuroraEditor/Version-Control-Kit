//
//  ProcessError.swift
//  
//
//  Created by Nanashi Li on 2024/07/02.
//

// Process Specific Errors
public enum ProcessError: Error {
    case launchFailed(String)
    case timeout
    case unexpectedExitCode(Int)
    case outputParsingFailed
}

extension ProcessError {
    var errorDescription: String? {
        switch self {
        case .launchFailed(let reason):
            return "Failed to launch process: \(reason)"
        case .timeout:
            return "Process execution timed out"
        case .unexpectedExitCode(let code):
            return "Process exited with unexpected code: \(code)"
        case .outputParsingFailed:
            return "Failed to parse process output"
        }
    }
}
