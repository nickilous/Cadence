//
//  DateRangeComponent.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

public protocol DateRangeComponent: QueryComponent {
    var startDate: Date { get }
    var endDate: Date { get }
}
