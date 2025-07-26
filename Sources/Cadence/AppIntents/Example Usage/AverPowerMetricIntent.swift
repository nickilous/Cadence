//
//  AverPowerMetricIntent.swift
//  
//
//  Created by Nicholas Hartman on 7/26/25.
//
#if canImport(AppIntents)
import Foundation
import AppIntents

public struct AveragePowerMetricIntent: AppIntent {
    public init() {}
    
    @Parameter(title: "Start Date", description: "The start date for the calculation")
    public var startDate: Date
    
    @Parameter(title: "End Date", description: "The end date for the calculation")
    public var endDate: Date
    
    public static let title: LocalizedStringResource = "Perform Metric Calculation"
    public static let description = IntentDescription("Performs a specific Metrics Calculation")
    

    public func perform() async throws -> some IntentResult {
        let averagePowerMetric: AveragePowerMetric = .init()
        let average = try await averagePowerMetric.compute(from: [], in: .init(seasonInterval: .init(startDate: startDate, endDate: endDate), builder: {
            
        }))
        return .result(value: average.convertToAppEntity() )
    }
}
#endif
