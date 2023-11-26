//
//  ComputedAction.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

enum ComputedAction {
    case clean([Commit])
    case conflicts
    case invalid
    case loading
}
