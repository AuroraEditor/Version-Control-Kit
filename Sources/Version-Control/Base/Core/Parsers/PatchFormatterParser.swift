//
//  PatchFormatterParser.swift
//
//
//  Created by Nanashi Li on 2023/11/13.
//

import Foundation

struct PatchFormatterParser {

    /// Constructs the header for a patch, indicating the original and new file paths.
    ///
    /// This function prepares the two-line header that precedes the diff content in a patch file. 
    /// The header lines begin with "---" and "+++", signaling the original and new file paths, respectively.
    ///
    /// - Parameters:
    ///   - fromPath: An optional `String` representing the path to the original file. If `nil`, implies the file is new.
    ///   - toPath: An optional `String` representing the path to the new file. If `nil`, implies the file was deleted.
    ///
    /// - Returns: A `String` that represents the header for a patch file.
    ///
    /// When either `fromPath` or `toPath` is `nil`, the path defaults to "/dev/null", which is a placeholder used in 
    /// diffs to indicate that the file did not exist in the "from" state or will not exist in the "to" state, corresponding to file creation
    /// or deletion. For existing files, the paths are prefixed with "a/" and "b/" to distinguish between the old and new files in a conventional manner.
    func formatPatchHeader(fromPath: String?, toPath: String?) -> String {
        let fromPath = fromPath != nil ? "a/\(fromPath!)" : "/dev/null"
        let toPath = toPath != nil ? "b/\(toPath!)" : "/dev/null"
        return "--- \(fromPath)\n+++ \(toPath)\n"
    }

    /// Generates a string representing the header for a patch file.
    ///
    /// This function creates the header for a patch based on the status of a file in the working directory. 
    /// The status determines whether the file is new, untracked, renamed, deleted, modified, copied, or conflicted, and adjusts the header accordingly.
    ///
    /// - Parameter file: A `WorkingDirectoryFileChange` object representing the file and its status.
    ///
    /// - Returns: A `String` representing the patch header for the given file.
    ///
    /// The header format typically includes the paths to the original and new files. For new or untracked files, 
    /// the header indicates that the file did not exist previously. For renamed, deleted, modified, copied, or conflicted files,
    /// the header shows that the file has a previous state from which it has been changed.
    /// The `formatPatchHeader` helper function is used to generate the appropriate header based on the file's status.

    func formatPatchHeaderForFile(file: WorkingDirectoryFileChange) -> String {
        switch file.status.kind {
        case .new, .untracked:
            return formatPatchHeader(fromPath: nil, toPath: file.path)
        case .renamed, .deleted, .modified, .copied, .conflicted:
            return formatPatchHeader(fromPath: file.path, toPath: file.path)
        }
    }

    /// Creates a string representing the header for a diff hunk.
    ///
    /// This function generates the header line for a hunk in a unified diff. A hunk represents a contiguous section of 
    /// changes in a text comparison. The header includes range information about the changes in the format used by tools like GNU diff.
    ///
    /// - Parameters:
    ///   - oldStartLine: An `Int` indicating the starting line number of the hunk in the original file.
    ///   - oldLineCount: An `Int` indicating the number of lines the hunk applies to in the original file.
    ///   - newStartLine: An `Int` indicating the starting line number of the hunk in the new file.
    ///   - newLineCount: An `Int` indicating the number of lines the hunk applies to in the new file.
    ///   - sectionHeading: An optional `String` representing a contextual heading for the hunk, such as a function or class name.
    ///
    /// - Returns: A `String` formatted as a unified diff hunk header.
    ///
    /// The hunk header format is "@@ -l,s +l,s @@", where l is the starting line number and s is the number of lines
    /// the hunk spans in the original and new files, respectively. The function computes `lineInfoBefore`
    /// and `lineInfoAfter` by checking if the `oldLineCount` and `newLineCount` equal 1, in which case the
    /// comma and s are omitted, following GNU diff's convention. If `sectionHeading` is provided, it is included in the header;
    /// otherwise, only the range information is included.

    func formatHunkHeader(oldStartLine: Int,
                          oldLineCount: Int,
                          newStartLine: Int,
                          newLineCount: Int,
                          sectionHeading: String? = nil) -> String {
        // The hunk range information contains two hunk ranges. The range for the hunk of the original
        // file is preceded by a minus symbol, and the range for the new file is preceded by a plus
        // symbol. Each hunk range is of the format l,s where l is the starting line number and s is
        // the number of lines the change hunk applies to for each respective file.
        //
        // In many versions of GNU diff, each range can omit the comma and trailing value s,
        // in which case s defaults to 1

        let lineInfoBefore = oldLineCount == 1 ? "\(oldStartLine)" : "\(oldStartLine),\(oldLineCount)"
        let lineInfoAfter = newLineCount == 1 ? "\(newStartLine)" : "\(newStartLine),\(newLineCount)"

        let heading = sectionHeading ?? ""
        let header = heading.isEmpty ? "" : " \(heading)"

        return "@@ -\(lineInfoBefore) +\(lineInfoAfter) @@\(header)\n"
    }

    /// Generates a patch string to discard selected changes from a file.
    ///
    /// This function constructs a patch designed to reverse selected additions and deletions from a file's diff, effectively 
    /// discarding those changes. It iterates over the hunks in the provided `TextDiff` and creates a buffer for each hunk,
    /// including only the selected lines that represent changes to be discarded.
    ///
    /// - Parameters:
    ///   - filePath: A `String` representing the path to the file being patched.
    ///   - diff: A `TextDiff` object representing the differences between the file versions.
    ///   - selection: A `DiffSelection` object that determines which changes are selected to be discarded.
    ///
    /// - Returns: An optional `String` containing the patch. Returns `nil` if the resulting patch would be empty, 
    ///            implying no changes need to be discarded.
    ///
    /// The function processes each line within a hunk according to its type. For selected added lines, it prefixes them with a
    /// minus sign to indicate their removal. For selected deleted lines, it prefixes them with a plus sign to indicate their addition back.
    /// Lines that are not selected remain unchanged in the resulting patch. If there are no selected changes within a hunk, it is skipped.
    ///
    /// After processing all hunks, the function checks if the resulting patch is empty. If it is, `nil` is returned, indicating 
    /// that no changes have been selected for discarding. Otherwise, it formats a patch header using the `filePath`
    /// and prepends it to the patch string before returning it.
    ///
    /// The use of a switch statement allows handling each line type explicitly and can be extended to support additional line types if necessary.
    func formatPatchToDiscardChanges(filePath: String,
                                     diff: TextDiff,
                                     selection: DiffSelection) -> String? {
        var patch = ""

        for hunk in diff.hunks {
            var hunkBuf = ""
            var oldCount = 0
            var newCount = 0
            var anyAdditionsOrDeletions = false

            for (lineIndex, line) in hunk.lines.enumerated() {
                let absoluteIndex = hunk.unifiedDiffStart + lineIndex

                switch line.type {
                case .hunk:
                    // Skip hunk headers
                    continue
                case .context:
                    hunkBuf += "\(line.text)\n"
                    oldCount += 1
                    newCount += 1
                case .add where selection.isSelected(lineIndex: absoluteIndex):
                    hunkBuf += "-\(line.text.dropFirst())\n"
                    newCount += 1
                    anyAdditionsOrDeletions = true
                case .delete where selection.isSelected(lineIndex: absoluteIndex):
                    hunkBuf += "+\(line.text.dropFirst())\n"
                    oldCount += 1
                    anyAdditionsOrDeletions = true
                case .add:
                    // Unselected added lines will stay after discarding changes
                    oldCount += 1
                    newCount += 1
                    hunkBuf += " \(line.text.dropFirst())\n"
                case .delete:
                    // Unselected deleted lines are ignored since they are not in the working copy
                    continue
                default:
                    // Handle unsupported line types if needed
                    fatalError("Unsupported line type \(line.type)")
                }

                if line.noTrailingNewLine {
                    hunkBuf += "\\ No newline at end of file\n"
                }
            }

            if !anyAdditionsOrDeletions {
                // Skip hunks with only context lines
                continue
            }

            patch += formatHunkHeader(oldStartLine: hunk.header.oldStartLine,
                                      oldLineCount: oldCount,
                                      newStartLine: hunk.header.newStartLine,
                                      newLineCount: newCount)
            patch += hunkBuf
        }

        if patch.isEmpty {
            // The selection resulted in an empty patch
            return nil
        }

        return formatPatchHeader(fromPath: filePath,
                                 toPath: filePath) + patch
    }

    /// Formats the patch for a given file and its differences.
    ///
    /// This function takes a `WorkingDirectoryFileChange` and a `TextDiff` and returns a string representing the patch that can be applied to the file.
    /// It iterates over the `hunks` in the `TextDiff` and constructs a patch by including only selected lines, additions, and deletions.
    ///
    /// - Parameters:
    ///   - file: A `WorkingDirectoryFileChange` object representing the file to which the patch will be applied.
    ///   - diff: A `TextDiff` object containing the differences between two sets of text.
    ///
    /// - Returns: A `String` representing the patch.
    ///
    /// - Throws: An `NSError` if no changes are present in the diff for the file.
    ///
    /// The function initializes an empty string `patch` to hold the final patch data. For each hunk in the diff, it checks the type of each 
    /// line (e.g., context, add, delete) and selectively includes them in the hunk buffer `hunkBuf`. It calculates the old and new
    /// line counts and determines if there are any changes within the hunk. Lines that are not selected and are part of new or
    /// untracked files are ignored unless they are deletions, which are then converted to context lines.
    ///
    /// If there are no changes within a hunk, the hunk is skipped. For each hunk with changes, a hunk header is formatted and
    /// appended to `patch` along with the `hunkBuf`. If no changes are detected across all hunks, an error is thrown
    /// indicating that no patch could be generated. Otherwise, the patch header is formatted and prepended to the `patch`, and the resulting patch string is returned.
    func formatPatch(file: WorkingDirectoryFileChange,
                     diff: TextDiff) throws -> String {
        var patch = ""

        for (_, hunk) in diff.hunks.enumerated() {
            var hunkBuf = ""
            var oldCount = 0
            var newCount = 0
            var anyAdditionsOrDeletions = false

            for (lineIndex, line) in hunk.lines.enumerated() {
                let absoluteIndex = hunk.unifiedDiffStart + lineIndex

                // Skip hunk lines
                if line.type == .hunk {
                    continue
                }

                // Context lines are always included
                if line.type == .context {
                    hunkBuf += "\(line.text)\n"
                    oldCount += 1
                    newCount += 1
                } else if file.selection.isSelected(lineIndex: absoluteIndex) {
                    // Selected line for inclusion
                    hunkBuf += "\(line.text)\n"

                    if line.type == .add {
                        newCount += 1
                    }
                    if line.type == .delete {
                        oldCount += 1
                    }

                    anyAdditionsOrDeletions = true
                } else if file.status.kind == .new || file.status.kind == .untracked {
                    // Unselected lines in new files are ignored
                    continue
                } else if line.type == .add {
                    // Unselected added lines are ignored
                    continue
                } else if line.type == .delete {
                    // Convert unselected deleted lines to context lines
                    hunkBuf += " \(line.text.dropFirst())\n"
                    oldCount += 1
                    newCount += 1
                }

                if line.noTrailingNewLine {
                    hunkBuf += "\\ No newline at end of file\n"
                }
            }

            // Skip hunk if there are no changes
            if !anyAdditionsOrDeletions {
                continue
            }

            // Add the hunk to the patch
            patch += formatHunkHeader(oldStartLine: hunk.header.oldStartLine,
                                      oldLineCount: oldCount, 
                                      newStartLine: hunk.header.newStartLine,
                                      newLineCount: newCount) + hunkBuf
        }

        if patch.isEmpty {
            throw NSError(domain: "com.yourApp.domain", 
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Could not generate a patch, no changes for file \(file.path)"])
        }

        patch = formatPatchHeaderForFile(file: file) + patch

        return patch
    }
}
