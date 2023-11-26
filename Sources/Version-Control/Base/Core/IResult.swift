//
//  IResult.swift
//  
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

/** The result of shelling out to git. */
protocol IResult {
    /** The standard output from git. */
    var stdout: String { get }

    /** The standard error output from git. */
    var stderr: String { get }

    /** The exit code of the git process. */
    var exitCode: Int { get }
}
