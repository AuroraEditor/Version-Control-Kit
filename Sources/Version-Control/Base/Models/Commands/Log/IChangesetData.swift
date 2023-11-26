//
//  IChangesetData.swift
//  
//
//  Created by Nanashi Li on 2023/11/25.
//

import Foundation

struct IChangesetData {
    /** Files changed in the changeset. */
    let files: [CommittedFileChange]

    /** Number of lines added in the changeset. */
    let linesAdded: Int

    /** Number of lines deleted in the changeset. */
    let linesDeleted: Int
}
