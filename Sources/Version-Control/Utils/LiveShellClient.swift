//
//  shellClient.swift
//  AuroraEditor
//
//  Created by Wesley de Groot on 22/07/2022.
//

import Foundation

public var sharedShellClient: LiveShellClient = .init()

// Inspired by: https://vimeo.com/291588126
public struct LiveShellClient {
    public var shellClient: ShellClient = .live()
}
