//
//  IProgress.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// Base protocol containing all the properties that progress events
/// need to support.
public protocol IProgress {
    /// The overall progress of the operation, represented as a fraction between
    /// 0 and 1.
    var value: Int { get }
    /// An informative text for user consumption indicating the current operation
    /// state. This will be high level such as 'Pushing origin' or
    /// 'Fetching upstream' and will typically persist over a number of progress
    /// events. For more detailed information about the progress see
    /// the description field
    var title: String? { get }
    /// An informative text for user consumption. In the case of git progress this
    /// will usually be the last raw line of output from git.
    var description: String? { get }
}

/// An object describing the progression of a branch checkout operation
public protocol ICheckoutProgress: IProgress {
    var kind: String { get }
    /// The branch that's currently being checked out
    var targetBranch: String { get }
}

public class CheckoutProgress: ICheckoutProgress {
    public var kind: String = "checkout"
    public var targetBranch: String
    public var value: Int
    public var title: String?
    public var description: String?

    init(kind: String = "checkout",
         targetBranch: String,
         value: Int,
         title: String? = nil,
         description: String? = nil) {
        self.kind = kind
        self.targetBranch = targetBranch
        self.value = value
        self.title = title
        self.description = description
    }
}

/// An object describing the progression of a fetch operation
public protocol IFetchProgress: IProgress {
    var kind: String { get }
    /// The remote that's being fetched
    var remote: String { get }
}

public class FetchProgress: IFetchProgress {
    public var kind: String = "fetch"
    public var remote: String
    public var value: Int
    public var title: String?
    public var description: String?

    init(remote: String, value: Int, title: String? = nil, description: String? = nil) {
        self.remote = remote
        self.value = value
        self.title = title
        self.description = description
    }
}

/// An object describing the progression of a pull operation
public protocol IPullProgress: IProgress {
    var kind: String { get }
    /// The remote that's being pulled from
    var remote: String { get }
}

public class PullProgress: IPullProgress {
    public var kind: String = "pull"
    public var remote: String
    public var value: Int
    public var title: String?
    public var description: String?

    init(kind: String? = "pull",
         remote: String,
         value: Int,
         title: String? = nil,
         description: String? = nil) {
        self.kind = kind!
        self.remote = remote
        self.value = value
        self.title = title
        self.description = description
    }
}

/// An object describing the progression of a pull operation
public protocol IPushProgress: IProgress {
    var kind: String { get }
    /// The remote that's being pushed to
    var remote: String { get }
    /// The branch that's being pushed
    var branch: String { get }
}

public class PushProgress: IPushProgress {
    public var kind: String = "push"
    public var remote: String
    public var branch: String
    public var value: Int
    public var title: String?
    public var description: String?

    init(remote: String, branch: String, value: Int, title: String? = nil, description: String? = nil) {
        self.remote = remote
        self.branch = branch
        self.value = value
        self.title = title
        self.description = description
    }
}

/// An object describing the progression of a fetch operation
public protocol ICloneProgress: IProgress {
    var kind: String { get }
}

public class CloneProgress: ICloneProgress {
    public var kind: String = "clone"
    public var value: Int
    public var title: String?
    public var description: String?

    init(kind: String = "clone",
         value: Int,
         title: String? = nil,
         description: String? = nil) {
        self.kind = kind
        self.value = value
        self.title = title
        self.description = description
    }
}

/// An object describing the progression of a revert operation.
public protocol IRevertProgress: IProgress {
    var kind: String { get }
}

public class RevertProgress: IRevertProgress {
    public var kind: String = "revert"
    public var value: Int
    public var title: String?
    public var description: String?

    init(kind: String,
         value: Int,
         title: String? = nil,
         description: String? = nil) {
        self.kind = kind
        self.value = value
        self.title = title
        self.description = description
    }
}

public protocol IMultiCommitOperationProgress: IProgress {
    var kind: String { get }
    /// The summary of the commit applied
    var currentCommitSummary: String { get }
    /// The number to signify which commit in a selection is being applied
    var position: Int { get }
    /// The total number of commits in the operation
    var totalCommitCount: Int { get }
}

public class MultiCommitOperationProgress: IMultiCommitOperationProgress {
    public var kind: String = "multiCommitOperation"
    public var currentCommitSummary: String
    public var position: Int
    public var totalCommitCount: Int
    public var value: Int
    public var title: String?
    public var description: String?

    init(kind: String = "multiCommitOperation",
         currentCommitSummary: String,
         position: Int,
         totalCommitCount: Int,
         value: Int,
         title: String? = nil,
         description: String? = nil) {
        self.kind = kind
        self.currentCommitSummary = currentCommitSummary
        self.position = position
        self.totalCommitCount = totalCommitCount
        self.value = value
        self.title = title
        self.description = description
    }
}
