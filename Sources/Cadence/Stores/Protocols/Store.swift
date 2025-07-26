//
//  Store.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public typealias OrganizedQueryResults<Result: Unit> = [TrainingSeason: [ActivityOptions: [MetricOptions: [SampleMetricContainer<Result>]]]]

public protocol Store {
    var supportedActivityTypes: [ActivityOptions] { get }
    var supportedMetricTypes: [MetricOptions] { get }
    
    var defaultUnits: [MetricOptions: Unit] { get }
    
    var isAvailable: Bool { get }
    
    func fetch<Result:Unit>(_ activity: ActivityOptions, metrics: MetricOptions, in season: TrainingSeason) async throws -> [SampleMetricContainer<Result>]
    func fetch<Result:Unit>(query: TrainingQuery) async throws -> [SampleMetricContainer<Result>]
    func fetchOrganized<Result:Unit>(query: TrainingQuery) async throws -> OrganizedQueryResults<Result>
    func requestAuthorization(for metricTypes: [MetricOptions], options: [AuthorizationOption]) async throws
}
#if canImport(HealthKit)
import HealthKit
extension HKHealthStore : Store {
    public var supportedActivityTypes: [ActivityOptions]{[]}
    public var supportedMetricTypes: [MetricOptions] { [.heartRate, .restingHeartRate] }
    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    public var defaultUnits: [MetricOptions : Unit] { [.runningPower: UnitPower.watts] }
    
    var activityConverters: ConverterComponent<ActivityOptions, HKWorkoutActivityType> {
        hkActivityTypeConverter
    }
    var metricConverters: [MetricOptions: ConverterComponent<MetricOptions, HKQuantityType>] { [:] }
    
   
    
    public func fetch<Result:Unit>(_ activity: ActivityOptions, metrics: MetricOptions, in season: TrainingSeason) async throws -> [SampleMetricContainer<Result>] {
        guard let unit = defaultUnits[metrics] as? Result else { throw CadenceError.noSupportedMetrics(metrics) }
        return [SampleMetricContainer<Result>(
            activity: activity,
            metric: metrics,
            startDate: season.startDate,
            endDate: season.endDate,
            measurment: Measurement(value: 10, unit: unit)
        )]
    }
    
    public func fetch<Result:Unit>(query: TrainingQuery) async throws -> [SampleMetricContainer<Result>] {
        var results: [SampleMetricContainer<Result>] = []
        
        let season = query.components.first(where: { $0 is TrainingSeason }) as? TrainingSeason
        guard let season = season else {
            throw CadenceError.unknownActivityOption("No TrainingSeason found in query")
        }
        
        let activityTargets = query.components.compactMap { $0 as? ActivityTargetComponent }
        
        for activityTarget in activityTargets {
            for metricTarget in activityTarget.metrics {
                let sampleData: [SampleMetricContainer<Result>] = try await fetch(activityTarget.activityTarget, metrics: metricTarget.metricTarget, in: season)
                results.append(contentsOf: sampleData)
            }
        }
        
        return results
    }
    
    public func fetchOrganized<Result:Unit>(query: TrainingQuery) async throws -> OrganizedQueryResults<Result> {
        var organizedResults: OrganizedQueryResults<Result> = [:]
        
        let season = query.components.first(where: { $0 is TrainingSeason }) as? TrainingSeason
        guard let season = season else {
            throw CadenceError.unknownActivityOption("No TrainingSeason found in query")
        }
        
        let activityTargets = query.components.compactMap { $0 as? ActivityTargetComponent }
        
        for activityTarget in activityTargets {
            for metricTarget in activityTarget.metrics {
                let sampleData: [SampleMetricContainer<Result>] = try await fetch(activityTarget.activityTarget, metrics: metricTarget.metricTarget, in: season)
                
                if organizedResults[season] == nil {
                    organizedResults[season] = [:]
                }
                if organizedResults[season]![activityTarget.activityTarget] == nil {
                    organizedResults[season]![activityTarget.activityTarget] = [:]
                }
                if organizedResults[season]![activityTarget.activityTarget]![metricTarget.metricTarget] == nil {
                    organizedResults[season]![activityTarget.activityTarget]![metricTarget.metricTarget] = []
                }
                
                organizedResults[season]![activityTarget.activityTarget]![metricTarget.metricTarget]!.append(contentsOf: sampleData)
            }
        }
        
        return organizedResults
    }
    
    public func requestAuthorization(for metricTypes: [MetricOptions], options: [AuthorizationOption]) async throws {
        var sampleTypes: Set<HKSampleType> = []
        for type in metricTypes {
            switch type {
            case .heartRate:
                sampleTypes.insert(HKQuantityType(.heartRate))
            case .restingHeartRate:
                sampleTypes.insert(HKQuantityType(.restingHeartRate))
            default: throw CadenceError.unknownMetricOption("in HKHealthStore requestAuthorization")
            }
        }
        if options.contains(.read) {
            try await self.requestAuthorization(toShare: [], read: sampleTypes)
        } else if options.contains(.write) {
            try await self.requestAuthorization(toShare: sampleTypes, read: [])
        } else if options.contains([.read, .write]) {
            try await self.requestAuthorization(toShare: sampleTypes, read: sampleTypes)
        }
    }
}
#endif
