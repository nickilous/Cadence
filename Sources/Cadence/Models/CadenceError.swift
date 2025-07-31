//
//  CadenceError.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation

/// Errors that can occur when using the Cadence framework.
///
/// `CadenceError` provides specific error cases for different failure scenarios
/// that can occur when working with training data, stores, and metric calculations.
/// All errors conform to `LocalizedError` to provide user-friendly error messages.
///
/// ## Error Handling
///
/// These errors are typically thrown by Store implementations, metric calculations,
/// and query processing operations:
///
/// ```swift
/// do {
///     let results = try await store.fetch(.running, metrics: .heartRate, in: season)
/// } catch CadenceError.noSupportedMetrics(let metric) {
///     print("Store doesn't support metric: \(metric)")
/// } catch CadenceError.noSupportedActivities(let activity) {
///     print("Store doesn't support activity: \(activity)")
/// } catch {
///     print("Other error occurred: \(error)")
/// }
/// ```
public enum CadenceError : Error, LocalizedError {
    /// An unknown or unsupported metric option was requested.
    ///
    /// This error occurs when trying to use a metric that the store or framework
    /// doesn't recognize or support. The associated string provides additional
    /// context about where the error occurred.
    ///
    /// - Parameter String: Additional context about the unknown metric option
    case unknownMetricOption(String)
    
    /// An unknown or unsupported activity option was requested.
    ///
    /// This error occurs when trying to use an activity type that the store or
    /// framework doesn't recognize or support. The associated string provides
    /// additional context about where the error occurred.
    ///
    /// - Parameter String: Additional context about the unknown activity option
    case unknownActivityOption(String)
    
    /// No available stores support the requested activities.
    ///
    /// This error occurs when all available stores lack support for the requested
    /// activity types. The associated value contains the activities that were requested.
    ///
    /// - Parameter ActivityOptions: The activity options that aren't supported
    case noSupportedActivities(ActivityOptions)
    
    /// No available stores support the requested metrics.
    ///
    /// This error occurs when all available stores lack support for the requested
    /// metric types. The associated value contains the metrics that were requested.
    ///
    /// - Parameter MetricOptions: The metric options that aren't supported
    case noSupportedMetrics(MetricOptions)
    
    /// A required parameter is missing for the operation.
    ///
    /// This error occurs when a metric calculation requires specific parameters
    /// (such as heart rate data) that are not available or not provided.
    ///
    /// - Parameter String: Description of the missing parameter
    case missingRequiredParameter(String)
    
    /// A user-readable description of the error.
    ///
    /// Provides localized error messages that can be displayed to users or logged
    /// for debugging purposes.
    public var errorDescription: String? {
        switch self {
        case .unknownMetricOption:
            return "Unknown metric option"
        case .unknownActivityOption:
            return "Unknown activity option"
        case .noSupportedActivities:
            return "No supported activities"
        case .noSupportedMetrics:
            return "No supported metrics"
        case .missingRequiredParameter(let parameter):
            return "Missing required parameter: \(parameter)"
        }
    }
}
