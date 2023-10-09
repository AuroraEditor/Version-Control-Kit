//
//  Diff-Data.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/29.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

private let maximumDiffStringSize = 268435441

public enum DiffType {
    /// Changes to a text file, which may be partially selected for commit
    case text
    /// Changes to a file with a known extension, which can be viewed in the editor
    case image
    /// Changes to an unknown file format, which Git is unable to present in a human-friendly format
    case binary
    /// Change to a repository which is included as a submodule of this repository
    case submodule
    /// Diff is large enough to degrade ux if rendered
    case largeText
    /// Diff that will not be rendered
    case unrenderable
}

public enum LineEndingType: String {
    // swiftlint:disable:next identifier_name
    case cr = "CR"
    // swiftlint:disable:next identifier_name
    case lf = "LF"
    case crlf = "CRLF"
}

public class LineEndingsChange {
    var from: LineEndingType
    var to: LineEndingType

    init(from: LineEndingType,
         to: LineEndingType) {
        self.from = from
        self.to = to
    }
}

/// Parse the line ending string into an enum value (or `null` if unknown)
public func parseLineEndingText(text: String) -> LineEndingType? {
    let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
    switch input {
    case "CR":
        return .cr
    case "LF":
        return .lf
    case "CRLF":
        return .crlf
    default:
        return nil
    }
}

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

public class ITextDiff: ITextDiffData {
    var kind: DiffType = .text
}

public class IImageDiff {
    var kind: DiffType = .image
}

public class IBinaryDiff {
    var kind: DiffType = .binary
}

public class ILargeTextDiff: ITextDiffData {
    var kind: DiffType = .largeText
}

public class IUnrenderableDiff {
    var kind: DiffType = .unrenderable
}

public enum IDiffTypes {
    case text(ITextDiff)
    case image(IImageDiff)
    case binary(IBinaryDiff)
    case large(ILargeTextDiff)
    case unrenderable(IUnrenderableDiff)
}
