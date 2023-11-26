//
//  IndexError.swift
//
//
//  Created by Nanashi Li on 2023/11/16.
//

import Foundation

enum IndexError: Error {
    case unknownIndex(String)
    case noRenameIndex(String)
    case invalidStatus(String)
}
