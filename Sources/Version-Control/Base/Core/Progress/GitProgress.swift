//
//  GitProgress.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

protocol GitParsingResult {
    var kind: String { get }
    var percent: Int { get }
}

struct ProgressStep {
    /**
     * The title of the git progress event. By title we refer to the
     * exact value of the title field in the Git progress struct.
     *
     * In essence this means anything up to (but not including) the last colon (:)
     * in a single progress line. Take this example progress line
     *
     *    remote: Compressing objects:  14% (159/1133)
     *
     * In this case the title would be 'remote: Compressing objects'.
     */
    let title: String

    /**
     * The weight of this step in relation to others for a particular
     * Git operation. This value can be any number as long as it's
     * proportional to others in the same parser, it will all be scaled
     * to a decimal value between 0 and 1 before being used to calculate
     * overall progress.
     */
    let weight: Double
}

struct IGitProgress: GitParsingResult {
    var kind: String = "progress"
    /**
     * The overall percent of the operation
     */
    var percent: Int

    /**
     * The underlying progress line that this progress instance was
     * constructed from. Note that the percent value in details
     * doesn't correspond to that of percent in this instance for
     * two reasons. Fist, we calculate percent by dividing value with total
     * to produce a high precision decimal value between 0 and 1 while
     * details.percent is a rounded integer between 0 and 100.
     *
     * Second, the percent in this instance is scaled in relation to any
     * other steps included in the progress parser.
     */
    var details: IGitProgressInfo
}

enum GitProgressKind {
    case progress(IGitProgress)
    case context(IGitOutput)
}

/**
 * Identifies a particular subset of progress events from Git by
 * title.
 */
struct IProgressStep {
    /**
     * The title of the git progress event. By title we refer to the
     * exact value of the title field in the Git progress struct.
     *
     * In essence this means anything up to (but not including) the last colon (:)
     * in a single progress line. Take this example progress line
     *
     *    remote: Compressing objects:  14% (159/1133)
     *
     * In this case the title would be 'remote: Compressing objects'.
     */
    let title: String

    /**
     * The weight of this step in relation to others for a particular
     * Git operation. This value can be any number as long as it's
     * proportional to others in the same parser, it will all be scaled
     * to a decimal value between 0 and 1 before being used to calculate
     * overall progress.
     */
    let weight: Double
}

struct IGitOutput: GitParsingResult {
    var kind: String = "context"
    let percent: Int
    let text: String
}

/**
 * A well-structured representation of a Git progress line.
 */
struct IGitProgressInfo {
    /**
     * The title of the git progress event. By title we refer to the
     * exact value of the title field in Git's progress struct.
     * In essence this means anything up to (but not including) the last colon (:)
     * in a single progress line. Take this example progress line
     *
     *    remote: Compressing objects:  14% (159/1133)
     *
     * In this case the title would be 'remote: Compressing objects'.
     */
    let title: String

    /**
     * The progress value as parsed from the Git progress line.
     *
     * We define value to mean the same as it does in the Git progress struct, i.e
     * it's the number of processed units.
     *
     * In the progress line 'remote: Compressing objects:  14% (159/1133)' the
     * value is 159.
     *
     * In the progress line 'remote: Counting objects: 123' the value is 123.
     *
     */
    let value: Int

    /**
     * The progress total as parsed from the git progress line.
     *
     * We define total to mean the same as it does in the Git progress struct, i.e
     * it's the total number of units in a given process.
     *
     * In the progress line 'remote: Compressing objects:  14% (159/1133)' the
     * total is 1133.
     *
     * In the progress line 'remote: Counting objects: 123' the total is undefined.
     *
     */
    let total: Int?

    /**
     * The progress percent as parsed from the git progress line represented as
     * an integer between 0 and 100.
     *
     * We define percent to mean the same as it does in the Git progress struct, i.e
     * it's the value divided by total.
     *
     * In the progress line 'remote: Compressing objects:  14% (159/1133)' the
     * percent is 14.
     *
     * In the progress line 'remote: Counting objects: 123' the percent is undefined.
     *
     */
    let percent: Int?

    /**
     * Whether or not the parsed git progress line indicates that the operation
     * is done.
     *
     * This is denoted by a trailing ", done" string in the progress line.
     * Example: Checking out files:  100% (728/728), done
     */
    let done: Bool

    /**
     * The untouched raw text line that this instance was parsed from. Useful
     * for presenting the actual output from Git to the user.
     */
    let text: String
}

let percentRePattern = "^(\\d{1,3})% \\((\\d+)/(\\d+)\\)$"
let valueOnlyRePattern = "^\\d+$"


/**
 * A utility class for interpreting progress output from `git`
 * and turning that into a percentage value estimating the overall progress
 * of the an operation. An operation could be something like `git fetch`
 * which contains multiple steps, each individually reported by Git as
 * progress events between 0 and 100%.
 *
 * A parser cannot be reused, it's mean to parse a single stderr stream
 * for Git.
 */
struct GitProgressParser {
    private let steps: [ProgressStep]

    /* The provided steps should always occur in order but some
     * might not happen at all (like remote compression of objects) so
     * we keep track of the "highest" seen step so that we can fill in
     * progress with the assumption that we've already seen the previous
     * steps.
     */
    private var stepIndex: Int = 0
    private var lastPercent: Double = 0

    /**
     * Initialize a new instance of a Git progress parser.
     *
     * @param steps - A series of steps that could be present in the git
     *                output with relative weight between these steps. Note
     *                that order is significant here as once the parser sees
     *                a progress line that matches a step all previous steps
     *                are considered completed and overall progress is adjusted
     *                accordingly.
     */
    init(steps: [ProgressStep]) throws {
        if steps.isEmpty {
            throw NSError(domain: "com.auroraeditor.editor", 
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Must specify at least one step"])
        }

        // Scale the step weight so that they're all a percentage
        // adjusted to the total weight of all steps.
        let totalStepWeight = steps.reduce(0.0) { $0 + $1.weight }

        self.steps = steps.map { step in
            let weight = step.weight / totalStepWeight
            return ProgressStep(title: step.title, weight: weight)
        }
    }

    mutating func parse(line: String) -> GitParsingResult {
        guard let progress = parse(line: line) else {
            return IGitOutput(kind: "context", percent: Int(lastPercent), text: line)
        }

        var percent: Double = 0

        for (index, step) in steps.enumerated() {
            if index >= stepIndex && progress.title == step.title {
                if progress.total ?? 0 > 0 {
                    percent += step.weight * Double(progress.value) / Double(progress.total ?? 0)
                }

                stepIndex = index
                lastPercent = percent

                return IGitProgress(kind: "progress", percent: Int(percent), details: progress)
            } else if index < stepIndex {
                percent += step.weight
            }
        }

        return IGitOutput(kind: "context", percent: Int(lastPercent), text: line)
    }

    func parse(line: String) -> IGitProgressInfo? {
        guard let titleRange = line.range(of: ": "), !titleRange.isEmpty else {
            return nil
        }

        let title = String(line[..<titleRange.lowerBound])
        let progressText = line[line.index(after: titleRange.upperBound)...].trimmingCharacters(in: .whitespaces)

        if progressText.isEmpty {
            return nil
        }

        let progressParts = progressText.split(separator: ",", omittingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        if progressParts.isEmpty {
            return nil
        }

        let percentRe = try! NSRegularExpression(pattern: #"^(\d{1,3})% \((\d+)\/(\d+)\)$"#)
        let valueOnlyRe = try! NSRegularExpression(pattern: #"^\d+$"#)

        var value: Int = 0
        var total: Int?
        var percent: Int?

        if valueOnlyRe.firstMatch(in: progressParts[0], options: [], range: NSRange(location: 0, length: progressParts[0].utf16.count)) != nil {
            value = Int(progressParts[0])!
        } else if let match = percentRe.firstMatch(in: progressParts[0], options: [], range: NSRange(location: 0, length: progressParts[0].utf16.count)) {
            let percentString = String(progressParts[0][Range(match.range(at: 1), in: progressParts[0])!])
            let valueString = String(progressParts[0][Range(match.range(at: 2), in: progressParts[0])!])
            let totalString = String(progressParts[0][Range(match.range(at: 3), in: progressParts[0])!])

            percent = Int(percentString)
            value = Int(valueString)!
            total = Int(totalString)
        } else {
            return nil
        }

        var done = false

        for part in progressParts.dropFirst() {
            if part == "done." {
                done = true
                break
            }
        }

        return IGitProgressInfo(title: title, value: value, total: total, percent: percent, done: done, text: line)
    }
}

