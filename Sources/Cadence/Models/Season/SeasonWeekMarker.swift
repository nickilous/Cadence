//
//  TrainingSeasonMarker.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation


public struct TrainingWeekMarker: Comparable, Hashable, Sendable {
    public var year: Int
    public var month: Int
    public var week: Int
    
    public var date: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.weekOfMonth = week
        return calendar.date(from: components) ?? Date()
    }
    
    public init(year: Int, month: Int, week: Int) {
        self.year = year
        self.month = month
        self.week = week
    }
    
    public static func < (lhs: TrainingWeekMarker, rhs: TrainingWeekMarker) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.week < rhs.week
    }
}

