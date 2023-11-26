//
//  ITextDiffData.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

/// Data returned as part of a textual diff from Aurora Editor
public class ITextDiffData {
    /// The unified text diff - including headers and context
    var text: String
    /// The diff contents organized by hunk - how the git CLI outputs to the caller
    var hunks: [DiffHunk]
    /// A warning from Git that the line endings have changed in this file and will affect the commit
    var lineEndingsChange: LineEndingsChange?
    /// The largest line number in the diff
    var maxLineNumber: Int
    /// Whether or not the diff has invisible bidi characters
    var hasHiddenBidiChars: Bool

    init(text: String, hunks: [DiffHunk],
         lineEndingsChange: LineEndingsChange? = nil,
         maxLineNumber: Int,
         hasHiddenBidiChars: Bool) {
        self.text = text
        self.hunks = hunks
        self.lineEndingsChange = lineEndingsChange
        self.maxLineNumber = maxLineNumber
        self.hasHiddenBidiChars = hasHiddenBidiChars
    }
}

public protocol TextDiff: ITextDiffData {
    var kind: DiffType { get set }
}


