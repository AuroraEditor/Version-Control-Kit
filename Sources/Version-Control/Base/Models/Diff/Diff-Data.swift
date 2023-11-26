//
//  Diff-Data.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/29.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

private let maximumDiffStringSize = 268435441

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
