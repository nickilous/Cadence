//
//  Converter.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/15/25.
//

import Foundation
import HealthKit

public struct ConverterComponent<In,Out>: QueryComponent where In: Sendable, Out: Sendable {
    public var id: UUID = .init()
    public var convert: @Sendable (In) throws -> Out
}


public let hkActivityTypeConverter = ConverterComponent<ActivityOptions, HKWorkoutActivityType> { activityOptions in
    switch activityOptions {
    case .running:
        return .running
    case .cycling:
        return .cycling
    case .swimming:
        return .swimming
    default:
        fatalError("Unknown activity type")
    }
}
