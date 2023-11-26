//
//  DiffImage.swift
//
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

/**
 * A container for holding an image for display in the application
 */
struct DiffImage {
    public var contents: String
    public var mediaType: String
    public var bytes: Int

    /**
     * @param contents The base64 encoded contents of the image.
     * @param mediaType The data URI media type, so the browser can render the image correctly.
     * @param bytes Size of the file in bytes.
     */
    public init(contents: String,
                mediaType: String,
                bytes: Int) {
        self.contents = contents
        self.mediaType = mediaType
        self.bytes = bytes
    }
}
