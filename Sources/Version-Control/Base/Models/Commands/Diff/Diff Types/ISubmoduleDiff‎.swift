//
//  ISubmoduleDiff‎.swift
//
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public struct ISubmoduleDiff : IDiff {
    public var kind: DiffType = .submodule

    /** Full path of the submodule */
    var fullPath: String

    /** Path of the repository within its container repository */
    var path: String

    /** URL of the submodule */
    var url: String? = nil

    /** Status of the submodule */
    var status: SubmoduleStatus

    /** Previous SHA of the submodule, or null if it hasn't changed */
    var oldSHA: String? = nil

    /** New SHA of the submodule, or null if it hasn't changed */
    var newSHA: String? = nil
}
