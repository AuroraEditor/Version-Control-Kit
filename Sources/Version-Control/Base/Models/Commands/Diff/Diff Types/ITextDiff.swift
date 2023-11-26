//
//  ITextDiff.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public class ITextDiff: ITextDiffData, TextDiff, IDiff {
    public var kind: DiffType = .text
}
