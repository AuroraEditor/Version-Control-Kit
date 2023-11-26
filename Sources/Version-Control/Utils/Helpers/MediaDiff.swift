//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public struct MediaDiff {

    public init() {}

    /// Returns the media type of a file as a string based on its file extension.
    ///
    /// The function compares the file extension to a set of known image file types
    /// and returns the corresponding media type. If the file extension is not recognized
    /// as one of the predefined image types, the function defaults to returning "text/plain".
    ///
    /// - Parameter extension: A string representing the file extension.
    /// - Returns: A string representing the media type of the file.
    ///
    /// # Example:
    /// ```
    /// let mediaType = getMediaType(extension: ".png") // Returns "image/png"
    /// ```
    ///
    /// - Note: This function currently supports the following image media types:
    ///   - PNG (.png)
    ///   - JPEG (.jpg, .jpeg)
    ///   - GIF (.gif)
    ///   - ICO (.ico)
    ///   - WEBP (.webp)
    ///   - BMP (.bmp)
    ///   - AVIF (.avif)
    func getMediaType(extension: String) -> String {
        if `extension` == ".png" {
            return "image/png"
        }
        if `extension` == ".jpg" || `extension` == ".jpeg" {
            return "image/jpg"
        }
        if `extension` == ".gif" {
            return "image/gif"
        }
        if `extension` == ".ico" {
            return "image/x-icon"
        }
        if `extension` == ".webp" {
            return "image/webp"
        }
        if `extension` == ".bmp" {
            return "image/bmp"
        }
        if `extension` == ".avif" {
            return "image/avif"
        }

        return "text/plain"
    }
}
