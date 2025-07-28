//
//  Store.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

/// A hierarchical dictionary structure for organizing query results by training season, activity type, and metric type.
///
/// This typealias provides a convenient way to access training data in a structured format:
/// - **First level**: `CadenceTrainingSeason` - The training season containing the data
/// - **Second level**: `ActivityOptions` - The type of activity (running, cycling, etc.)
/// - **Third level**: `MetricOptions` - The specific metric (heart rate, power, etc.)
/// - **Fourth level**: Array of `SampleMetricContainer<Result>` - The actual sample data
///
/// ## Usage
///
/// ```swift
/// let results: OrganizedQueryResults<UnitPower> = try await store.fetchOrganized(query: query)
/// 
/// // Access running heart rate data for a specific season
/// if let heartRateData = results[season]?[.running]?[.heartRate] {
///     for sample in heartRateData {
///         print("Heart Rate: \(sample.measurment)")
///     }
/// }
/// ```
public typealias OrganizedQueryResults<Result: Unit> = [CadenceTrainingSeason: [ActivityOptions: [MetricOptions: [SampleMetricContainer<Result>]]]]

/// A protocol defining the interface for data stores that can provide training and fitness metrics.
///
/// The `CadenceStore` protocol abstracts different data sources (like HealthKit, third-party fitness apps, or custom databases)
/// behind a common interface for fetching training data. Stores can support different combinations of activities
/// and metrics, and provide both individual data fetching and complex query-based operations.
///
/// ## Conforming Types
///
/// - `HKHealthStore` - Apple's HealthKit integration (iOS/macOS only)
/// - Custom stores for third-party fitness platforms
/// - Mock stores for testing
///
/// ## Core Capabilities
///
/// - **Activity Support**: Each store declares which activity types it can provide data for
/// - **Metric Support**: Each store declares which metrics it can measure
/// - **Authorization**: Stores handle their own permission and authorization flows
/// - **Query System**: Advanced querying with multiple activities and metrics
///
/// ## Usage Example
///
/// ```swift
/// let healthStore = HKHealthStore()
/// 
/// // Check capabilities
/// if healthStore.supportedMetricTypes.contains(.heartRate) {
///     // Fetch individual metric
///     let heartRateData = try await healthStore.fetch(.running, metrics: .heartRate, in: season)
///     
///     // Or use complex queries
///     let queryResults = try await healthStore.fetch(query: trainingQuery)
/// }
/// ```
public protocol CadenceStore {
    /// The activity types that this store can provide data for.
    ///
    /// Different stores may support different subsets of activities. For example, a running-focused
    /// store might only support `.running`, while a comprehensive fitness store might support
    /// `.running`, `.cycling`, `.swimming`, and more.
    var supportedActivityTypes: [ActivityOptions] { get }
    
    /// The metric types that this store can provide data for.
    ///
    /// Each store declares which metrics it can measure and provide. Common metrics include
    /// heart rate, power, distance, and energy expenditure.
    var supportedMetricTypes: [MetricOptions] { get }
    
    /// The default units for each supported metric type.
    ///
    /// This mapping defines the preferred unit for each metric. For example, power might default
    /// to watts, while heart rate defaults to beats per minute.
    var defaultUnits: [MetricOptions: Unit] { get }
    
    /// Whether this store is currently available for use.
    ///
    /// This property indicates if the store can currently provide data. For example, HealthKit
    /// might not be available on certain platforms or if the user hasn't granted permissions.
    var isAvailable: Bool { get }
    
    /// Fetches training data for a specific activity and metric within a training season.
    ///
    /// This is the fundamental data fetching method that retrieves samples for a single
    /// activity-metric combination during a specific training season.
    ///
    /// - Parameters:
    ///   - activity: The type of activity to fetch data for
    ///   - metrics: The specific metric to retrieve
    ///   - season: The training season that defines the time range for data retrieval
    /// - Returns: An array of sample containers with the requested metric data
    /// - Throws: `CadenceError.noSupportedMetrics` if the metric isn't supported, or other store-specific errors
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// let heartRateData = try await store.fetch(
    ///     .running, 
    ///     metrics: .heartRate, 
    ///     in: trainingSeason
    /// )
    /// 
    /// for sample in heartRateData {
    ///     print("Heart rate: \(sample.measurment)")
    /// }
    /// ```
    func fetch<Result:Unit>(_ activity: ActivityOptions, metrics: MetricOptions, in season: CadenceTrainingSeason) async throws -> [SampleMetricContainer<Result>]
    
    /// Fetches training data using a complex query with multiple activities and metrics.
    ///
    /// This method processes a `TrainingQuery` that can contain multiple activity targets,
    /// each with multiple metrics, providing a more flexible way to retrieve related data
    /// in a single operation.
    ///
    /// - Parameter query: A training query containing activity targets, metrics, and season information
    /// - Returns: A flat array containing all sample data matching the query criteria
    /// - Throws: `CadenceError.unknownActivityOption` if no training season is found in the query, or other store-specific errors
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// let query = TrainingQuery(id: UUID()) {
    ///     CadenceTrainingSeason(seasonInterval: interval) { /* phases */ }
    ///     ActivityTargetComponent(activityTarget: .running) {
    ///         MetricTargetComponent(metricTarget: .heartRate)
    ///         MetricTargetComponent(metricTarget: .runningPower)
    ///     }
    /// }
    /// 
    /// let results = try await store.fetch(query: query)
    /// ```
    func fetch<Result:Unit>(query: TrainingQuery) async throws -> [SampleMetricContainer<Result>]
    
    /// Fetches training data using a complex query and organizes results hierarchically.
    ///
    /// This method provides the same querying capabilities as `fetch(query:)` but returns
    /// results in a structured format that makes it easy to access data by season, activity,
    /// and metric type. This is particularly useful for complex queries spanning multiple
    /// activities and metrics.
    ///
    /// - Parameter query: A training query containing activity targets, metrics, and season information
    /// - Returns: Hierarchically organized results as `[CadenceTrainingSeason: [ActivityOptions: [MetricOptions: [SampleMetricContainer<Result>]]]]`
    /// - Throws: `CadenceError.unknownActivityOption` if no training season is found in the query, or other store-specific errors
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// let organizedResults = try await store.fetchOrganized(query: complexQuery)
    /// 
    /// // Access specific data easily
    /// if let runningHeartRate = organizedResults[season]?[.running]?[.heartRate] {
    ///     let avgHeartRate = runningHeartRate.map { $0.measurment.value }.reduce(0, +) / Double(runningHeartRate.count)
    ///     print("Average heart rate: \(avgHeartRate) bpm")
    /// }
    /// ```
    func fetchOrganized<Result:Unit>(query: TrainingQuery) async throws -> OrganizedQueryResults<Result>
    
    /// Requests authorization to access specific metric types.
    ///
    /// Different stores may require different authorization flows. For example, HealthKit
    /// requires explicit user permission for each data type, while other stores might
    /// use API keys or OAuth flows.
    ///
    /// - Parameters:
    ///   - metricTypes: The metric types that the app wants to access
    ///   - options: The type of access requested (read, write, or both)
    /// - Throws: Store-specific authorization errors or `CadenceError.unknownMetricOption` for unsupported metrics
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// try await store.requestAuthorization(
    ///     for: [.heartRate, .runningPower], 
    ///     options: [.read]
    /// )
    /// ```
    func requestAuthorization(for metricTypes: [MetricOptions], options: [AuthorizationOption]) async throws
}

#if canImport(HealthKit)
import HealthKit

/// HealthKit integration for the Store protocol.
///
/// This extension provides HealthKit support for fetching training and fitness data on iOS and macOS.
/// HealthKit is Apple's framework for health and fitness data, providing access to data from the
/// Health app, Apple Watch, and third-party health apps.
///
/// ## Platform Availability
///
/// HealthKit is only available on iOS and macOS. This extension is conditionally compiled and will
/// only be available on supported platforms.
///
/// ## Supported Metrics
///
/// Currently supports:
/// - Heart rate measurements
/// - Resting heart rate measurements
///
/// ## Authorization
///
/// HealthKit requires explicit user permission for each data type. Use `requestAuthorization(for:options:)`
/// to request access before fetching data.
///
/// ## Usage Example
///
/// ```swift
/// let healthStore = HKHealthStore()
/// 
/// // Check if HealthKit is available
/// guard healthStore.isAvailable else {
///     print("HealthKit not available on this device")
///     return
/// }
/// 
/// // Request authorization
/// try await healthStore.requestAuthorization(for: [.heartRate], options: [.read])
/// 
/// // Fetch data
/// let heartRateData = try await healthStore.fetch(.running, metrics: .heartRate, in: season)
/// ```
extension HKHealthStore : CadenceStore {
    /// The activity types supported by this HealthKit store.
    ///
    /// Currently returns an empty array as activity-specific filtering is handled
    /// through workout types in the internal implementation.
    public var supportedActivityTypes: [ActivityOptions]{[]}
    
    /// The metric types that this HealthKit store can provide.
    ///
    /// Returns the health metrics that can be fetched from HealthKit on this device.
    /// Additional metrics may be added based on device capabilities and HealthKit updates.
    public var supportedMetricTypes: [MetricOptions] { [.heartRate, .restingHeartRate] }
    
    /// Whether HealthKit is available on this device.
    ///
    /// Returns `true` if HealthKit is supported and available on the current device,
    /// `false` otherwise. HealthKit is not available on all iOS devices and is not
    /// supported on some platforms.
    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    public var defaultUnits: [MetricOptions : Unit] { [.runningPower: UnitPower.watts] }
    
    var activityConverters: ConverterComponent<ActivityOptions, HKWorkoutActivityType> {
        hkActivityTypeConverter
    }
    var metricConverters: [MetricOptions: ConverterComponent<MetricOptions, HKQuantityType>] { [:] }
    
   
    
    public func fetch<Result:Unit>(_ activity: ActivityOptions, metrics: MetricOptions, in season: CadenceTrainingSeason) async throws -> [SampleMetricContainer<Result>] {
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
        
        let season = query.components.first(where: { $0 is CadenceTrainingSeason }) as? CadenceTrainingSeason
        guard let season = season else {
            throw CadenceError.unknownActivityOption("No CadenceTrainingSeason found in query")
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
        
        let season = query.components.first(where: { $0 is CadenceTrainingSeason }) as? CadenceTrainingSeason
        guard let season = season else {
            throw CadenceError.unknownActivityOption("No CadenceTrainingSeason found in query")
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
