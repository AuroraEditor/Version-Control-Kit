//
//  IDiffTypes.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

public enum IDiffTypes {
    case text(ITextDiff)
    case image(IImageDiff)
    case binary(IBinaryDiff)
    case large(ILargeTextDiff)
    case unrenderable(IUnrenderableDiff)
}
