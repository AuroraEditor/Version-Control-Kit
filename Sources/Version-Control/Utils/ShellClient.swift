//  Created by Wesley de Groot on 17/08/22.
//
import Foundation
import Combine

/// Shell Client
/// Run commands in shell
public class ShellClient {
    /// Generate a process and pipe to run commands
    /// - Parameter args: commands to run
    /// - Returns: command output
    func generateProcessAndPipe(_ args: [String]) -> (Process, Pipe) {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c"] + args
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        return (task, pipe)
    }

    /// Generate a process and pipe to run commands
    /// - Parameters:
    ///   - commandPath: The path to the command to run (e.g., "/usr/bin/git")
    ///   - arguments: The arguments to pass to the command
    ///   - workingDirectory: The working directory for the command
    /// - Returns: A tuple containing the Process and Pipe
    func generateProcessAndPipe(_ arguments: [String],
                                workingDirectory: String?) -> (Process, Pipe) {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c"] + arguments
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        if let workingDirectory = workingDirectory {
            task.currentDirectoryPath = workingDirectory
        }

        return (task, pipe)
    }

    /// Cancellable tasks
    var cancellables: [UUID: AnyCancellable] = [:]

    /// Run a command
    /// - Parameter args: command to run
    /// - Returns: command output
    @discardableResult
    public func run(_ args: String...) throws -> String {
        let (task, pipe) = generateProcessAndPipe(args)

        // Configure task
        task.launch()
        task.waitUntilExit()

        // Read data from the pipe
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        // Check if the task exited with a non-zero status code (indicating an error)
        if task.terminationStatus != 0 {
            throw CommandError.nonZeroExitStatus(Int(task.terminationStatus))
        }

        // Convert data to a string
        if let outputString = String(data: data, encoding: .utf8) {
            return outputString
        } else {
            throw CommandError.utf8ConversionFailed
        }
    }

    /// Run a command and capture its output
    /// - Parameters:
    ///   - commandPath: The path to the command to run (e.g., "/usr/bin/git")
    ///   - arguments: The arguments to pass to the command
    ///   - workingDirectory: The working directory for the command
    /// - Returns: The captured output of the command
    @discardableResult
    public func runAndCaptureOutput(arguments: [String],
                                    workingDirectory: String?) throws -> String {
        let (task, pipe) = generateProcessAndPipe(arguments, workingDirectory: workingDirectory)

        // Configure task
        task.launch()
        task.waitUntilExit()

        // Read data from the pipe
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        // Check if the task exited with a non-zero status code (indicating an error)
        if task.terminationStatus != 0 {
            throw CommandError.nonZeroExitStatus(Int(task.terminationStatus))
        }

        // Convert data to a string
        if let outputString = String(data: data, encoding: .utf8) {
            return outputString
        } else {
            throw CommandError.utf8ConversionFailed
        }
    }

    /// Run a command with Publisher
    /// - Parameter args: command to run
    /// - Returns: command output
    @discardableResult
    public func runLive(_ args: String...) -> AnyPublisher<String, Never> {
        let subject = PassthroughSubject<String, Never>()
        let (task, pipe) = generateProcessAndPipe(args)
        let outputHandler = pipe.fileHandleForReading

        outputHandler.waitForDataInBackgroundAndNotify()

        let id = UUID()
        self.cancellables[id] = NotificationCenter
            .default
            .publisher(for: .NSFileHandleDataAvailable, object: outputHandler)
            .sink { _ in
                let data = outputHandler.availableData
                guard !data.isEmpty else {
                    // If no data is available anymore, clean up and finish
                    self.cancellables.removeValue(forKey: id)
                    subject.send(completion: .finished)
                    return
                }
                if let line = String(data: data, encoding: .utf8)?
                    .split(whereSeparator: \.isNewline) {
                    line
                        .map(String.init)
                        .forEach(subject.send(_:))
                }
                outputHandler.waitForDataInBackgroundAndNotify() // Wait for more data
            }

        task.launch() // Start the task

        return subject.eraseToAnyPublisher()
    }

    func run(arguments: [String],
             workingDirectory: String) throws -> (stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw NSError(domain: "Git command execution error", code: Int(process.terminationStatus), userInfo: [
                "stdout": stdoutString,
                "stderr": stderrString
            ])
        }

        return (stdoutString, stderrString)
    }


    /// Shell client
    /// - Returns: description
    public static func live() -> ShellClient {
        return ShellClient()
    }
}
