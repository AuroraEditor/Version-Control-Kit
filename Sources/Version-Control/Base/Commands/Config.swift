//
//  Config.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/16.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Config {

    public init() {}

    /// Look up a Git configuration value by name within a specific repository context.
    ///
    /// This function retrieves a Git configuration value within the context of a specific Git repository \
    /// by reading the repository's path and then using the `getConfigValueInPath` function to \
    /// perform the configuration value lookup.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - name: The name of the Git configuration key to look up.
    ///   - onlyLocal: Whether or not the value should be retrieved from local repository settings only. \
    ///                Default is `false`, which means both local and global settings are considered.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value lookup process.
    ///
    /// - Returns:
    ///   The string value associated with the specified Git configuration key in the context of the repository, \
    ///   or `nil` if the configuration key is not found.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///
    ///   do {
    ///       if let configValue = try getConfigValue(directoryURL: directoryURL, name: configName, onlyLocal: true) {
    ///           print("Git configuration value for '\(configName)' in the repository: \(configValue)")
    ///       } else {
    ///           print("Git configuration key '\(configName)' not found in the repository.")
    ///       }
    ///   } catch {
    ///       print("Error looking up Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function retrieves a Git configuration value within a specific repository context 
    ///   by reading the repository's path and then using the `getConfigValueInPath` function with the provided path.
    public func getConfigValue(directoryURL: URL,
                               name: String,
                               onlyLocal: Bool = false) throws -> String? {
        return try getConfigValueInPath(name: name,
                                        path: directoryURL,
                                        onlyLocal: onlyLocal,
                                        type: nil)
    }

    /// Look up a global Git configuration value by name.
    ///
    /// This function retrieves a Git configuration value from the global Git configuration file based
    /// on the provided `name`.
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration key to look up.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value lookup process.
    ///
    /// - Returns:
    ///   The string value associated with the specified Git configuration key, 
    ///   or `nil` if the configuration key is not found.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.name" // Replace with the desired configuration name
    ///
    ///   do {
    ///       if let configValue = try getGlobalConfigValue(name: configName) {
    ///           print("Git configuration value for '\(configName)': \(configValue)")
    ///       } else {
    ///           print("Git configuration key '\(configName)' not found.")
    ///       }
    ///   } catch {
    ///       print("Error looking up Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function retrieves a global Git configuration value using the `getConfigValueInPath` 
    ///   function with appropriate parameters.
    public func getGlobalConfigValue(
        path: URL,
        name: String
    ) throws -> String? {
        return try getConfigValueInPath(name: name,
                                        path: path,
                                        onlyLocal: false,
                                        type: nil)
    }

    /// Look up a global Git configuration value by name and interpret it as a boolean.
    ///
    /// This function retrieves a Git configuration value from the global Git configuration file
    /// based on the provided `name` and interprets it as a boolean value according to Git's definition of
    /// boolean configuration values (e.g., "0" -> `false`, "off" -> `false`, "yes" -> `true`, etc.).
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration key to look up.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value lookup process.
    ///
    /// - Returns:
    ///   A `Bool` representing the interpreted boolean value of the Git configuration, 
    ///   or `nil` if the configuration key is not found or its value cannot be interpreted as a boolean.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "core.autocrlf" // Replace with the desired configuration name
    ///
    ///   do {
    ///       if let isAutoCrlfEnabled = try getGlobalBooleanConfigValue(name: configName) {
    ///           print("Auto CRLF handling is enabled: \(isAutoCrlfEnabled)")
    ///       } else {
    ///           print("Git configuration key '\(configName)' not found or not a boolean value.")
    ///       }
    ///   } catch {
    ///       print("Error looking up Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function retrieves and interprets a global Git configuration value as a boolean by
    ///   using the `getConfigValueInPath` function with appropriate parameters.
    public func getGlobalBooleanConfigValue(
        path: URL,
        name: String
    ) throws -> Bool? {
        let value = try getConfigValueInPath(name: name,
                                             path: path,
                                             onlyLocal: false,
                                             type: Bool.self)
        return value == nil ? nil : (value != nil) != false
    }

    /// Retrieves a Git configuration value with a specified name within a given context (global, local, or repository).
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to retrieve.
    ///   - path: The optional path specifying the context (local repository directory) in which to \
    ///           retrieve the configuration value. If `nil`, the configuration value is retrieved globally.
    ///   - onlyLocal: A Boolean flag indicating whether to retrieve the configuration value only from \
    ///                the local repository configuration (default is `false`). If `true`, \
    ///                the global configuration is not considered.
    ///   - type: An optional type to specify the expected type of the configuration value \
    ///           (e.g., "string", "int", "bool"). If `nil`, no type filtering is applied.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value retrieval process.
    ///
    /// - Returns:
    ///   The value of the retrieved Git configuration, or `nil` if the configuration value does not exist.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let localRepositoryPath = "/path/to/repo" // Replace with the path to the local repository (if applicable)
    ///
    ///   do {
    ///       if let configValue = try getConfigValueInPath(name: configName, path: localRepositoryPath) {
    ///           print("Git configuration value '\(configName)': \(configValue)")
    ///       } else {
    ///           print("Git configuration value '\(configName)' not found.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - If `path` is `nil`, the configuration value is retrieved globally.
    ///   - If `onlyLocal` is `true`, the global configuration is not considered.
    ///   - The `type` parameter is optional and can be used to specify the expected type of the configuration value.
    public func getConfigValueInPath(name: String,
                                     path: URL,
                                     onlyLocal: Bool = false,
                                     type: Any?) throws -> String? {

        var gitCommand: String

        var flags = ["config", "-z"]

        if onlyLocal {
            flags.append("--local")
        } else {
            flags.append("--global")
        }

        if let type = type {
            flags.append("--type \(type)")
        }

        flags.append(name)

        let result = try GitShell().git(
            args: flags,
            path: path,
            name: #function,
            options: IGitExecutionOptions(
                successExitCodes: Set([0, 1])
            )
        )

        // Git exits with 1 if the value isn't found. That's OK.
        if (result.exitCode == 1) {
            return nil
        }

        let output = result.stdout
        let pieces = output.split(separator: "\0")
        return pieces[0].description
    }

    /// Get the path to the global git config.
    /// Retrieves the path to the global Git configuration file.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the retrieval process.
    ///
    /// - Returns:
    ///   The path to the global Git configuration file, or `nil` if the configuration file is not found.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       if let globalConfigPath = try getGlobalConfig() {
    ///           print("Global Git configuration file path: \(globalConfigPath)")
    ///       } else {
    ///           print("Global Git configuration file not found.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving global Git configuration: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function retrieves the path to the global Git configuration file by parsing the 
    ///   output of the `git config` command.
    public func getGlobalConfig() throws -> String? {
        let result = try ShellClient.live().run(
            "git config --global --list --show-origin --name-only -z"
        )

        let segments = result.split(separator: "\0")
        if segments.count < 1 {
            return nil
        }

        let pathSegment = segments[0]
        if pathSegment.isEmpty {
            return nil
        }

        let path = pathSegment.ranges(of: "file:/")
        if path.count < 2 {
            return nil
        }

        return path[1].description
    }

    /// Sets a Git configuration value within a specific repository context.
    ///
    /// This function sets a Git configuration value within the context of a specific 
    /// Git repository by reading the repository's path and then using the `setConfigValueInPath` 
    /// function to perform the configuration value setting.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - name: The name of the Git configuration key to set.
    ///   - value: The value to set for the Git configuration key.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value setting process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let configValue = "example@email.com" // Replace with the desired configuration value
    ///
    ///   do {
    ///       try setConfigValue(directoryURL: directoryURL, name: configName, value: configValue)
    ///       print("Git configuration value '\(configName)' set in the repository.")
    ///   } catch {
    ///       print("Error setting Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function sets a Git configuration value within a specific repository context by
    ///   reading the repository's path and then using the `setConfigValueInPath` function with the provided path.
    public func setConfigValue(directoryURL: URL,
                               name: String,
                               value: String) throws {
        try setConfigValueInPath(name: name,
                                 value: value,
                                 path: String(contentsOf: directoryURL))
    }

    /// Sets a global Git configuration value by name.
    ///
    /// This function sets a Git configuration value in the global context. \
    /// It updates the global Git configuration file with the specified key-value pair.
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration key to set.
    ///   - value: The value to set for the Git configuration key.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value setting process.
    ///
    /// - Returns:
    ///   The result of the Git command executed to set the configuration value.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let configValue = "example@email.com" // Replace with the desired configuration value
    ///
    ///   do {
    ///       let result = try setGlobalConfigValue(name: configName, value: configValue)
    ///       print("Global Git configuration value set successfully. Result: \(result)")
    ///   } catch {
    ///       print("Error setting global Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function sets a Git configuration value in the global context using the
    ///   `setConfigValueInPath` function with `path` set to `nil`.
    ///
    /// - SeeAlso:
    ///   - `setConfigValueInPath(name:value:path:)`
    ///
    /// - Warning:
    ///   Changing global Git configuration values can affect the behavior of Git commands and may
    ///   impact all repositories on the system.
    public func setGlobalConfigValue(name: String,
                                     value: String) throws -> String {
        return try setConfigValueInPath(name: name,
                                        value: value,
                                        path: nil)
    }

    /// Adds a Git configuration value to the global Git configuration file.
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to add.
    ///   - value: The value to set for the Git configuration.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value addition process.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let configValue = "example@email.com" // Replace with the desired configuration value
    ///
    ///   do {
    ///       try addGlobalConfigValue(name: configName, value: configValue)
    ///       print("Git global configuration value added.")
    ///   } catch {
    ///       print("Error adding Git global configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function adds a Git configuration value to the global Git configuration file using the 
    ///   `git config` command with the `--global --add` flags.
    public func addGlobalConfigValue(name: String,
                                     value: String) throws {
        try ShellClient().run(
            "git config --global --add \(name) \(value)"
        )
    }

    /// Adds a directory path to the `safe.directories` Git configuration variable if it's not already present.
    ///
    /// Adding a path to `safe.directories` causes Git to ignore ownership differences for files within that directory.
    ///
    /// - Parameters:
    ///   - path: The directory path to add to the `safe.directories` configuration.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration addition process.
    ///
    /// - Note:
    ///   If the specified `path` is not already present in the `safe.directories` configuration, 
    ///   it is added using the `addGlobalConfigValueIfMissing` function.
    ///
    /// - SeeAlso:
    ///   - `addGlobalConfigValueIfMissing(name:value:)`
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryPath = "/path/to/safe/dir" // Replace with the desired safe directory path
    ///
    ///   do {
    ///       try addSafeDirectory(path: directoryPath)
    ///       print("Safe directory added: \(directoryPath)")
    ///   } catch {
    ///       print("Error adding safe directory: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Adding a path to `safe.directories` may affect Git's behavior with regard to ownership
    ///   differences within the specified directory.
    public func addSafeDirectory(path: String) throws {
        try addGlobalConfigValueIfMissing(name: "safe.directory",
                                          value: path)
    }

    /// Adds a Git configuration value to the global Git configuration file if it does not already exist.
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to add.
    ///   - value: The value to set for the Git configuration.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value addition process.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let configValue = "example@email.com" // Replace with the desired configuration value
    ///
    ///   do {
    ///       try addGlobalConfigValueIfMissing(name: configName, value: configValue)
    ///       print("Git global configuration value added or already exists.")
    ///   } catch {
    ///       print("Error adding Git global configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function checks if the specified Git configuration value \
    ///   already exists in the global Git configuration file. If it does not exist, \
    ///   it adds the value using the `git config` command with the `--global -z --get-all` flags.

    public func addGlobalConfigValueIfMissing(name: String,
                                              value: String) throws {
        let result = try ShellClient.live().run(
            "git config --global -z --get-all \(name) \(value)"
        )

        if result.split(separator: "\0").description.contains(value) {
            try addGlobalConfigValue(name: name, value: value)
        }
    }

    /// Sets a Git configuration value in a specified context (global or local).
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to set.
    ///   - value: The value to set for the Git configuration.
    ///   - path: The optional path specifying the context (local repository directory) \
    ///           in which to set the configuration value. If `nil`, the configuration value is set globally.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value setting process.
    ///
    /// - Returns:
    ///   The result of the Git command executed to set the configuration value.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.name" // Replace with the desired configuration name
    ///   let configValue = "John Doe" // Replace with the desired configuration value
    ///   let localRepositoryPath = "/path/to/repo" // Replace with the path to the local repository (if applicable)
    ///
    ///   do {
    ///       let result = try setConfigValueInPath(name: configName, value: configValue, path: localRepositoryPath)
    ///       print("Git configuration value set successfully. Result: \(result)")
    ///   } catch {
    ///       print("Error setting Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - If `path` is `nil`, the configuration value is set globally.
    ///   - This function sets the Git configuration value using the `git config` command with the `--replace-all` flag.
    @discardableResult
    public func setConfigValueInPath(name: String,
                                     value: String,
                                     path: String?) throws -> String {

        var gitCommand: String

        var flags = ["config"]

        if path == nil {
            flags.append("--global")
        }

        flags.append("--replace-all")
        flags.append(name)
        flags.append(value)

        if let path = path {
            gitCommand = "cd \(path.escapedWhiteSpaces()); git \(flags)"
        } else {
            gitCommand = "git \(flags)"
        }

        return try ShellClient.live().run(gitCommand)
    }

    /// Removes a Git configuration value within a specific repository context.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - name: The name of the Git configuration value to remove.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value removal process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///
    ///   do {
    ///       try removeConfigValue(directoryURL: directoryURL, name: configName)
    ///       print("Git configuration value '\(configName)' removed from the repository.")
    ///   } catch {
    ///       print("Error removing Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function removes a Git configuration value within the context of a specific Git repository 
    ///   by reading the repository's path and then using the `removeConfigValueInPath` function to perform the removal.
    public func removeConfigValue(directoryURL: URL,
                                  name: String) throws {
        try removeConfigValueInPath(name: name,
                                    path: String(contentsOf: directoryURL))
    }

    /// Removes a Git configuration value from the global Git configuration file.
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to remove.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value removal process.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///
    ///   do {
    ///       try removeGlobalConfigValue(name: configName)
    ///       print("Git global configuration value '\(configName)' removed.")
    ///   } catch {
    ///       print("Error removing Git global configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function removes a Git configuration value from the global Git configuration file
    ///   using the `removeConfigValueInPath` function with `path` set to `nil`.
    public func removeGlobalConfigValue(name: String) throws {
        try removeConfigValueInPath(name: name, path: nil)
    }

    /// Removes all occurrences of a Git configuration value with a specified name within a given context
    /// (global or local).
    ///
    /// - Parameters:
    ///   - name: The name of the Git configuration value to remove.
    ///   - path: The optional path specifying the context (local repository directory) \
    ///           in which to remove the configuration value. \
    ///           If `nil`, the configuration value is removed globally.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the configuration value removal process.
    ///
    /// - Important:
    ///   This function assumes that Git is installed and available in the system's PATH.
    ///
    /// - Example:
    ///   ```swift
    ///   let configName = "user.email" // Replace with the desired configuration name
    ///   let localRepositoryPath = "/path/to/repo" // Replace with the path to the local repository (if applicable)
    ///
    ///   do {
    ///       try removeConfigValueInPath(name: configName, path: localRepositoryPath)
    ///       print("Git configuration value '\(configName)' removed.")
    ///   } catch {
    ///       print("Error removing Git configuration value: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   If `path` is `nil`, the configuration value is removed globally; otherwise, 
    ///   it's removed within the specified local repository context.
    public func removeConfigValueInPath(name: String,
                                        path: String?) throws {
        var gitCommand: String

        var flags = ["config"]

        if path == nil {
            flags.append("--global")
        }

        flags.append("--unset-all")
        flags.append(name)

        if let path = path {
            gitCommand = "cd \(path.escapedWhiteSpaces()); git \(flags)"
        } else {
            gitCommand = "git \(flags)"
        }

        try ShellClient().run(gitCommand)
    }
} // swiftlint:disable:this file_length
