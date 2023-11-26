//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public protocol IDiff {
    var kind: DiffType { get set }
}

public struct Diff: IDiff {
    public var kind: DiffType
}
