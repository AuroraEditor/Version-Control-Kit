//
//  CommandError.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

enum CommandError: Error {
    case nonZeroExitStatus(Int) // Error with a non-zero exit status
    case utf8ConversionFailed   // Error when UTF-8 conversion of output fails
}
