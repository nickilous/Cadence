//
//  SampleMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation

public protocol SampleMetric<U> : Sample {
    associatedtype U:Unit
    var activity: ActivityOptions {get}
    var startDate: Date {get}
    var endDate: Date {get}
    var measurment: Measurement<U> {get}
}

public extension SampleMetric {
    static func result<U:Unit>(activity: ActivityOptions, metric: MetricOptions, startDate: Date, endDate: Date, value: Double, unit: U) -> Self where Self == SampleMetricContainer<U> {
        .init(activity: activity, metric: metric, startDate: startDate, endDate: endDate, measurment: .init(value: value, unit: unit))
    }
}


#if canImport(AppIntents)
public extension SampleMetric where U == UnitPower {
    func convertToAppEntity() -> PowerMetricEntity {
        .init(id: self.id as! UUID,
              type: .average,
              startDate: self.startDate,
              endDate: self.endDate,
              measurement: self.measurment)
    }
}
#endif
