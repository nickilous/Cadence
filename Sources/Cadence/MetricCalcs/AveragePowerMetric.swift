//
//  Average.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//
    
import Foundation

public extension Collection where Element == any SampleMetric<UnitPower> {
    var unit: UnitPower { first!.measurment.unit }
}

public protocol SampleMetricCollection : Collection, Sample {
    associatedtype U:Unit
    var unit: U { get }
}



public struct AveragePowerMetric: MetricCalc {
    public var id: UUID = .init()
    
    public var description: String { "Average Power" }
    
    public var activities: ActivityOptions { .running }
    public var metrics: MetricOptions { .runningPower }
    
    
    public func compute(from store: [Store], in season: TrainingSeason) async throws -> some SampleMetric<UnitPower> {
        var supported = store.compactMap { store in
            if (store.supportedActivityTypes.contains(activities) && store.supportedMetricTypes.contains(metrics))
            { return store }
            else
            { return nil }
        }
        guard !supported.isEmpty else {
            throw CadenceError.noSupportedActivities(activities)
        }
        var sampleMetrics: [any SampleMetric<UnitPower>] = []
        
        for store in supported {
            var metric: [any SampleMetric<UnitPower>] = try await store.fetch(activities, metrics: metrics, in: season)
            sampleMetrics = sampleMetrics + metric
        }
        
        let total = sampleMetrics.reduce(0.0) { partialResult, samples in
            return partialResult + samples.measurment.value
        }
        
        let average = total / Double(sampleMetrics.count)
        
        return .result(activity: activities,
                       metric: metrics,
                       startDate: season.startDate,
                       endDate: season.endDate,
                       value: average,
                       unit: sampleMetrics.unit)
    }
}
