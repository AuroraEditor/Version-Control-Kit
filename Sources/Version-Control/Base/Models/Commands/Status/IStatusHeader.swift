//
//  StatusHeader.swift
//
//
//  Created by Nanashi Li on 2023/11/21.
//

import Foundation

protocol IStatusHeader {
    var kind: String { get set }
    var value: String { get set }
}

struct StatusHeader: IStatusHeader {
    var kind: String
    var value: String
}
