//
//  IGitResult.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

public struct IGitResult: IResult {
    public var stdout: String
    public var stderr: String
    public let exitCode: Int
    public let gitError: GitError?
    public var gitErrorDescription: String?
    public let combinedOutput: String
    public let path: String
}
