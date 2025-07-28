//
//  HeartRateEntity.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/25/25.
//
#if canImport(AppIntents)
import Foundation
import AppIntents

public enum EntityType: String, AppEnum, CaseIterable {
    case average = "average"
    case max = "max"
    case min = "min"
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Entity Type")
    public static let caseDisplayRepresentations: [EntityType : DisplayRepresentation] = [.average: .init(title: "Average"),
                                                                                   .max: .init(title: "Max"),
                                                                                   .min: .init(title: "Min")]
}


public struct PowerMetricEntity : AppEntity {
    public typealias DefaultQuery = PowerMetricEntityQuery
    
    public var id: UUID
    public var type: EntityType
    public var startDate: Date
    public var endDate: Date
    public var measurement: Measurement<UnitPower>
    
    
    public var displayRepresentation: DisplayRepresentation {
        let image = "bolt.fill"
        let subtitle = LocalizedStringResource(
            "You have performed an average of \(measurement.formatted()).")

        
        if #available(macOS 14.0, iOS 16.0, *) {
            return DisplayRepresentation(title: "Power Metric",
                                         subtitle: subtitle,
                                         image: DisplayRepresentation.Image(systemName: image),
                                         synonyms: ["Activity Summary"])
        } else {
            return DisplayRepresentation(title: "Power Metric")
        }
    }
    
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Workout Summary")
    public static let defaultQuery: DefaultQuery = .init()
}

public struct PowerMetricEntityQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [PowerMetricEntity] {
       return []
    }
}
#endif
