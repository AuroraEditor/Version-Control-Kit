//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

enum StatusItem {
    case header(IStatusHeader)
    case entry(IStatusEntry)
}

struct GitStatusParser {

    let ChangedEntryType = "1"
    let RenamedOrCopiedEntryType = "2"
    let UnmergedEntryType = "u"
    let UntrackedEntryType = "?"
    let IgnoredEntryType = "!"

    let changedEntryRegex = try! NSRegularExpression(pattern: "^1 ([MADRCUTX?!.]{2}) (N\\\\.\\.\\.|S[C.][M.][U.]) (\\d+) (\\d+) (\\d+) ([a-f0-9]+) ([a-f0-9]+) ([\\s\\S]*?)$",
                                                     options: [])
    let renamedOrCopiedEntryRegex = try! NSRegularExpression(pattern: "^2 ([MADRCUTX?!.]{2}) (N\\\\.\\.\\.|S[C.][M.][U.]) (\\d+) (\\d+) (\\d+) ([a-f0-9]+) ([a-f0-9]+) ([RC]\\d+) ([\\s\\S]*?)$",
                                                             options: [])
    let unmergedEntryRegex = try! NSRegularExpression(pattern: "^u ([DAU]{2}) (N\\\\.\\.\\.|S[C.][M.][U.]) (\\d+) (\\d+) (\\d+) (\\d+) ([a-f0-9]+) ([a-f0-9]+) ([a-f0-9]+) ([\\s\\S]*?)$",
                                                      options: [])

    func parsePorcelainStatus(output: String) -> [StatusItem] {
        var entries = [StatusItem]()
        let tokens = output.split(separator: "\0")

        for token in tokens {
            if token.hasPrefix("# ") {
                let value = String(token.dropFirst(2))
                entries.append(.header(StatusHeader(kind: "header",
                                            value: value)))
                continue
            }

            let entryKind = String(token.prefix(1))

            switch entryKind {
            case ChangedEntryType:
                if let parsedEntry = parseChangedEntry(field: String(token)) {
                    entries.append(.entry(parsedEntry))
                }
            case RenamedOrCopiedEntryType:
                if let parsedEntry = parseRenamedOrCopiedEntry(field: String(token), oldPath: nil) {
                    entries.append(.entry(parsedEntry))
                }
            case UnmergedEntryType:
                if let parsedEntry = parseUnmergedEntry(field: String(token)) {
                    entries.append(.entry(parsedEntry))
                }
            case UntrackedEntryType:
                if let parsedEntry = parseUntrackedEntry(field: String(token)) {
                    entries.append(.entry(parsedEntry))
                }
            case IgnoredEntryType:
                // Ignored, we don't care about these for now
                break
            default:
                break
            }
        }

        return entries
    }

    func parseChangedEntry(field: String) -> IStatusEntry? {
        let nsRange = NSRange(field.startIndex..<field.endIndex, in: field)

        guard let match = changedEntryRegex.firstMatch(in: field, options: [], range: nsRange) else {
            print("parseChangedEntry parse error: \(field)")
            return nil
        }

        let statusCodeRange = Range(match.range(at: 1), in: field)!
        let submoduleStatusCodeRange = Range(match.range(at: 2), in: field)!
        let pathRange = Range(match.range(at: 8), in: field)!

        let statusCode = String(field[statusCodeRange])
        let submoduleStatusCode = String(field[submoduleStatusCodeRange])
        let path = String(field[pathRange])

        return StatusEntry(kind: .entry,
                            path: path,
                            statusCode: statusCode,
                            submoduleStatusCode: submoduleStatusCode,
                            oldPath: nil)
    }

    func parseRenamedOrCopiedEntry(field: String,
                                   oldPath: String?) -> IStatusEntry? {
        let nsRange = NSRange(field.startIndex..<field.endIndex, in: field)

        guard let match = renamedOrCopiedEntryRegex.firstMatch(in: field, options: [], range: nsRange) else {
            print("parseRenamedOrCopiedEntry parse error: \(field)")
            return nil
        }

        guard let oldPath = oldPath else {
            print("Failed to parse renamed or copied entry, could not parse old path")
            return nil
        }

        let statusCodeRange = Range(match.range(at: 1), in: field)!
        let submoduleStatusCodeRange = Range(match.range(at: 2), in: field)!
        let pathRange = Range(match.range(at: 9), in: field)!

        let statusCode = String(field[statusCodeRange])
        let submoduleStatusCode = String(field[submoduleStatusCodeRange])
        let path = String(field[pathRange])

        return StatusEntry(kind: .entry,
                            path: path,
                            statusCode: statusCode,
                            submoduleStatusCode: submoduleStatusCode,
                            oldPath: oldPath)
    }

    func parseUnmergedEntry(field: String) -> IStatusEntry? {
        let nsRange = NSRange(field.startIndex..<field.endIndex, in: field)

        guard let match = unmergedEntryRegex.firstMatch(in: field, options: [], range: nsRange) else {
            print("parseUnmergedEntry parse error: \(field)")
            return nil
        }

        let statusCodeRange = Range(match.range(at: 1), in: field)!
        let submoduleStatusCodeRange = Range(match.range(at: 2), in: field)!
        let pathRange = Range(match.range(at: 10), in: field)!

        let statusCode = String(field[statusCodeRange])
        let submoduleStatusCode = String(field[submoduleStatusCodeRange])
        let path = String(field[pathRange])

        return StatusEntry(kind: .entry,
                            path: path,
                            statusCode: statusCode,
                            submoduleStatusCode: submoduleStatusCode,
                            oldPath: nil)
    }

    func parseUntrackedEntry(field: String) -> IStatusEntry? {
        let path = String(field.dropFirst(2))
        return StatusEntry(kind: .entry,
                            path: path,
                            statusCode: "??",
                            submoduleStatusCode: "????",
                            oldPath: nil)
    }

    func mapStatus(statusCode: String,
                   submoduleStatusCode: String) -> FileEntry {

        var submoduleStatus = mapSubmoduleStatus(submoduleStatusCode: submoduleStatusCode)

        if statusCode == "??" {
            return UntrackedEntry(submoduleStatus: submoduleStatus)
        }

        if statusCode == ".M" {
            return OrdinaryEntry(type: .modified,
                                 index: GitStatusEntry.unchanged,
                                 workingTree: GitStatusEntry.modified,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == "M." {
            return OrdinaryEntry(type: .added,
                                 index: GitStatusEntry.unchanged,
                                 workingTree: GitStatusEntry.added,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == ".A" {
            return OrdinaryEntry(type: .added,
                                 index: GitStatusEntry.unchanged,
                                 workingTree: GitStatusEntry.added,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == "A." {
            return OrdinaryEntry(type: .added,
                                 index: GitStatusEntry.added,
                                 workingTree: GitStatusEntry.unchanged,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == ".D" {
            return OrdinaryEntry(type: .deleted,
                                 index: GitStatusEntry.unchanged,
                                 workingTree: GitStatusEntry.deleted,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == "D." {
            return OrdinaryEntry(type: .deleted,
                                 index: GitStatusEntry.deleted,
                                 workingTree: GitStatusEntry.unchanged,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == ".R" {
            return RenamedOrCopiedEntry(kind: .renamed,
                                        index: GitStatusEntry.unchanged,
                                        workingTree: GitStatusEntry.renamed,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == "R." {
            return RenamedOrCopiedEntry(kind: .renamed,
                                        index: GitStatusEntry.renamed,
                                        workingTree: GitStatusEntry.unchanged,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == ".C" {
            return RenamedOrCopiedEntry(kind: .copied,
                                        index: GitStatusEntry.unchanged,
                                        workingTree: GitStatusEntry.copied,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == "C." {
            return RenamedOrCopiedEntry(kind: .copied,
                                        index: GitStatusEntry.copied,
                                        workingTree: GitStatusEntry.unchanged,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == "AD" {
            return OrdinaryEntry(type: .added,
                                 index: GitStatusEntry.added,
                                 workingTree: GitStatusEntry.deleted,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == "AM" {
            return OrdinaryEntry(type: .added,
                                 index: GitStatusEntry.added,
                                 workingTree: GitStatusEntry.modified,
                                 submoduleStatus: submoduleStatus)
        }

        if statusCode == "RM" {
            return RenamedOrCopiedEntry(kind: .renamed,
                                        index: GitStatusEntry.renamed,
                                        workingTree: GitStatusEntry.modified,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == "RD" {
            return RenamedOrCopiedEntry(kind: .renamed,
                                        index: GitStatusEntry.renamed,
                                        workingTree: GitStatusEntry.deleted,
                                        submoduleStatus: submoduleStatus)
        }

        if statusCode == "DD" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.BothDeleted,
                                                                      us: GitStatusEntry.deleted,
                                                                      them: GitStatusEntry.deleted))
        }

        if statusCode == "AU" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.AddedByUs,
                                                                      us: GitStatusEntry.added,
                                                                      them: GitStatusEntry.updatedButUnmerged))
        }

        if statusCode == "UD" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.DeletedByThem,
                                                                      us: GitStatusEntry.updatedButUnmerged,
                                                                      them: GitStatusEntry.deleted))
        }

        if statusCode == "UA" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.AddedByThem,
                                                                      us: GitStatusEntry.updatedButUnmerged,
                                                                      them: GitStatusEntry.added))
        }

        if statusCode == "DU" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.DeletedByUs,
                                                                      us: GitStatusEntry.deleted,
                                                                      them: GitStatusEntry.updatedButUnmerged))
        }

        if statusCode == "AA" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.BothAdded,
                                                                      us: GitStatusEntry.added,
                                                                      them: GitStatusEntry.added))
        }

        if statusCode == "UU" {
            return ManualConflictEntry(submoduleStatus: submoduleStatus,
                                       details: ManualConflictDetails(submoduleStatus: submoduleStatus,
                                                                      action: UnmergedEntrySummary.BothModified,
                                                                      us: GitStatusEntry.updatedButUnmerged,
                                                                      them: GitStatusEntry.updatedButUnmerged))
        }

        return OrdinaryEntry(type: .modified,
                             index: nil,
                             workingTree: nil,
                             submoduleStatus: submoduleStatus)

    }

    func mapSubmoduleStatus(submoduleStatusCode: String) -> SubmoduleStatus? {
        guard submoduleStatusCode.starts(with: "S") else {
            return nil
        }

        return SubmoduleStatus(
            commitChanged: submoduleStatusCode.substring(1) == "C",
            modifiedChanges: submoduleStatusCode.substring(2) == "M",
            untrackedChanges: submoduleStatusCode.substring(3) == "U"
        )
    }
}
