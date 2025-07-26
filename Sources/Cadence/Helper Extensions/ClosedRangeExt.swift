//
//  ClosedRangeExt.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public extension ClosedRange where Bound == TrainingWeekMarker {
    var startDate: Date {
        return self.lowerBound.date
    }
    var endDate: Date {
        return self.upperBound.date
    }
    
    init(startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let startMarker = TrainingWeekMarker(year: calendar.component(.year, from: startDate),
                                               month: calendar.component(.month, from: startDate),
                                               week: calendar.component(.weekOfYear, from: startDate))
        let endMarker = TrainingWeekMarker(year: calendar.component(.year, from: endDate),
                                             month: calendar.component(.month, from: endDate),
                                             week: calendar.component(.weekOfYear, from: endDate))
                                             
                                             
        self.init(uncheckedBounds: (lower: startMarker, upper: endMarker))
    }
}
