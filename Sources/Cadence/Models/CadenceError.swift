//
//  CadenceError.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation

public enum CadenceError : Error, LocalizedError {
    case unknownMetricOption(String)
    case unknownActivityOption(String)
    case noSupportedActivities(ActivityOptions)
    case noSupportedMetrics(MetricOptions)
    
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
        }
    }
}
