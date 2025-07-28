//
//  TrainingQuery.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

/// A structured query for fetching complex training data across multiple activities and metrics.
///
/// `TrainingQuery` provides a declarative way to specify what training data you want to fetch
/// from data stores. It supports complex scenarios like fetching multiple metrics for different
/// activities within specific training seasons and phases.
///
/// ## Components
///
/// A training query is built using various components:
/// - **CadenceTrainingSeason**: Defines the time period and training phases
/// - **ActivityTargetComponent**: Specifies which activities to include
/// - **MetricTargetComponent**: Specifies which metrics to fetch for each activity
///
/// ## Builder Pattern
///
/// Training queries use a result builder pattern (@QueryComponentBuilder) that provides
/// a clean, declarative syntax for constructing complex queries.
///
/// ## Usage Examples
///
/// **Simple Query:**
/// ```swift
/// let query = TrainingQuery(id: UUID()) {
///     CadenceTrainingSeason(seasonInterval: seasonRange) {
///         CadenceTrainingPhase(activityType: .running, phaseType: .building, trainingWeekRange: range)
///     }
///     ActivityTargetComponent(activityTarget: .running) {
///         MetricTargetComponent(metricTarget: .heartRate)
///     }
/// }
/// ```
///
/// **Multi-Activity Query:**
/// ```swift
/// let query = TrainingQuery(id: UUID()) {
///     CadenceTrainingSeason(seasonInterval: seasonRange) { /* phases */ }
///     ActivityTargetComponent(activityTarget: .running) {
///         MetricTargetComponent(metricTarget: .heartRate)
///         MetricTargetComponent(metricTarget: .runningPower)
///     }
///     ActivityTargetComponent(activityTarget: .cycling) {
///         MetricTargetComponent(metricTarget: .heartRate)
///         MetricTargetComponent(metricTarget: .cyclingPower)
///     }
/// }
/// ```
///
/// ## Fetching Data
///
/// Once constructed, use the query with any `CadenceStore` to fetch data:
/// ```swift
/// let results = try await store.fetch(query: query)
/// let organizedResults = try await store.fetchOrganized(query: query)
/// ```
public struct TrainingQuery: Identifiable, Sendable {
    /// Unique identifier for this query.
    public var id: UUID = .init()
    
    /// The components that make up this query.
    ///
    /// Components define what data to fetch and how to organize it. They include
    /// training seasons, activity targets, and metric specifications.
    public var components: [any QueryComponent]
    
    /// Creates a new training query with the specified components.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the query
    ///   - components: A result builder closure that returns the query components
    public init(id: UUID, @QueryComponentBuilder components: () -> [any QueryComponent]) {
        self.id = id
        self.components = components()
    }
}
