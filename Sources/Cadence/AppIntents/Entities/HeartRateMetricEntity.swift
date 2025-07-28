//
//  HeartRateMetricEntity.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/28/25.
//
#if canImport(AppIntents)
import Foundation
import AppIntents

public enum HeartRateEntityType: String, AppEnum, CaseIterable {
    case regular = "regular"
    case resting = "resting"
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Entity Type")
    public static let caseDisplayRepresentations: [HeartRateEntityType : DisplayRepresentation] = [
        .regular: .init(title: "Regular"),
        .resting: .init(title: "Resting")
    ]
}

public struct HeartRateMetricEntity : AppEntity {
    public typealias DefaultQuery = HeartRateMetricEntityQuery
    
    public var id: UUID
    public var heartRateType: HeartRateEntityType
    public var type: EntityType
    public var startDate: Date
    public var endDate: Date
    public var measurement: Measurement<UnitFrequency>
    
    
    public var displayRepresentation: DisplayRepresentation {
        let image = "heart.fill"
        let subtitle = LocalizedStringResource(
            "You have performed an average of \(measurement.formatted()).")

        
        if #available(macOS 14.0, iOS 16.0, *) {
            return DisplayRepresentation(title: "Heart Rate Metric",
                                         subtitle: subtitle,
                                         image: DisplayRepresentation.Image(systemName: image),
                                         synonyms: ["Heart Rate Summary"])
        } else {
            return DisplayRepresentation(title: "Heart Rate Metric")
        }
    }
    
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Heart Rate Summary")
    public static let defaultQuery: DefaultQuery = .init()
}

public struct HeartRateMetricEntityQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [HeartRateMetricEntity] {
       return []
    }
}
#endif
