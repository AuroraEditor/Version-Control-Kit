//
//  IExecutionOptions.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

protocol IExecutionOptions {
    var env: [String: String]? { get set }
    var stdin: String? { get set }
    var stdinEncoding: String? { get set }
    var maxBuffer: Int? { get set }
    var processCallback: ((Process) -> Void)? { get set }
}
