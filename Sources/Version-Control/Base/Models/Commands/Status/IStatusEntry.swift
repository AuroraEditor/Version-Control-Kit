//
//  StatusEntry.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

enum StatusEntryKind {
    case entry
}

protocol IStatusEntry {
    var kind: StatusEntryKind { get set }
    var path: String { get set }
    var statusCode: String { get set }
    var submoduleStatusCode: String { get set }
    var oldPath: String? { get set }
}

struct StatusEntry: IStatusEntry {
    var kind: StatusEntryKind
    var path: String
    var statusCode: String
    var submoduleStatusCode: String
    var oldPath: String?
}
