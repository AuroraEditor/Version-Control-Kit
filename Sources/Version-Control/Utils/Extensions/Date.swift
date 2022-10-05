//
//  File.swift
//  
//
//  Created by Nanashi Li on 2022/10/05.
//

import Foundation

public extension Date {

    func yearMonthDayFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }

    func gitDateFormat(commitDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "E MMM dd HH:mm:ss yyyy Z"
        return dateFormatter.date(from: commitDate)
    }
}
