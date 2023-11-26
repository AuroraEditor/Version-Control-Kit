//
//  IImageDiff.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public struct IImageDiff: IDiff {
    public var kind: DiffType = .image

    /**
     * The previous image, if the file was modified or deleted
     *
     * Will be undefined for an added image
     */
    var previous: DiffImage?

    /**
     * The current image, if the file was added or modified
     *
     * Will be undefined for a deleted image
     */
    var current: DiffImage?
}
