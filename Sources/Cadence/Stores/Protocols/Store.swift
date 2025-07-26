//
//  Store.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation
import HealthKit

public protocol Store {
    var supportedActivityTypes: [ActivityOptions] { get }
    var supportedMetricTypes: [MetricOptions] { get }
    
    var defaultUnits: [MetricOptions: Unit] { get }
    
    var isAvailable: Bool { get }
    
    func fetch<Result:Unit>(_ activity: ActivityOptions, metrics: MetricOptions, in season: TrainingSeason) async throws -> [SampleMetricContainer<Result>]
    func requestAuthorization(for metricTypes: [MetricOptions], options: [AuthorizationOption]) async throws
}

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
 

