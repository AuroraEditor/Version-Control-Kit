//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public struct IGitExecutionOptions: IExecutionOptions {
    var env: [String : String]?
    var stdin: String?
    var stdinEncoding: String?
    var maxBuffer: Int?
    var processCallback: ((Process) -> Void)?
    var successExitCodes: Set<Int>?
    var expectedErrors: Set<GitError>?
    var trackLFSProgress: Bool?
}
