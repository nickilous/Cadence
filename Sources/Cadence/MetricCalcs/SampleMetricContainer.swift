//
//  SampleResultsContainer.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation


public struct SampleMetricContainer<U:Unit>: SampleMetric {
    public var id: UUID = .init()
    public var activity: ActivityOptions
    public var metric: MetricOptions
    public var startDate: Date
    public var endDate: Date
    public var measurment: Measurement<U>
}




