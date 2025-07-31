//
//  TRIMPMetricEntity.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//
#if canImport(AppIntents)
import Foundation
import AppIntents

public enum TRIMPEntityType: String, AppEnum, CaseIterable {
    case banister = "banister"
    case edwards = "edwards"
    case lucia = "lucia"
    case trainingLoad = "trainingLoad"
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "TRIMP Type")
    public static let caseDisplayRepresentations: [TRIMPEntityType : DisplayRepresentation] = [
        .banister: .init(title: "Banister"),
        .edwards: .init(title: "Edwards"),
        .lucia: .init(title: "Lucia"),
        .trainingLoad: .init(title: "Training Load")
    ]
}

public struct TRIMPMetricEntity : AppEntity {
    public typealias DefaultQuery = TRIMPMetricEntityQuery
    
    public var id: UUID
    public var trimpType: TRIMPEntityType
    public var type: EntityType
    public var startDate: Date
    public var endDate: Date
    public var measurement: Measurement<UnitTRIMP>
    
    
    public var displayRepresentation: DisplayRepresentation {
        let image = "heart.text.square.fill"
        let subtitle = LocalizedStringResource(
            "You have a TRIMP score of \(measurement.formatted()).")

        
        if #available(macOS 14.0, iOS 16.0, *) {
            return DisplayRepresentation(title: "TRIMP Metric",
                                         subtitle: subtitle,
                                         image: DisplayRepresentation.Image(systemName: image),
                                         synonyms: ["TRIMP Summary", "Training Impulse"])
        } else {
            return DisplayRepresentation(title: "TRIMP Metric")
        }
    }
    
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "TRIMP Summary")
    public static let defaultQuery: DefaultQuery = .init()
}

public struct TRIMPMetricEntityQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [TRIMPMetricEntity] {
       return []
    }
}
#endif