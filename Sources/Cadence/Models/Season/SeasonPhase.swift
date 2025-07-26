//
//  TrainingPhase.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public enum PhaseType : CaseIterable, Sendable {
    case base
    case building
    case peak
}

public struct TrainingPhase: Identifiable, Hashable, Sendable {
    public var id: UUID = .init()
    public var activityType: ActivityOptions
    public var phaseType: PhaseType
    public var trainingWeekRange: TrainingWeekRange
    
    public init(id: UUID, activityType: ActivityOptions, phaseType: PhaseType, trainingWeekRange: TrainingWeekRange) {
        var id = id
        self.activityType = activityType
        self.phaseType = phaseType
        self.trainingWeekRange = trainingWeekRange
    }
    
    public static func == (lhs: TrainingPhase, rhs: TrainingPhase) -> Bool {
        lhs.id == rhs.id &&
        lhs.activityType == rhs.activityType &&
        lhs.phaseType == rhs.phaseType &&
        lhs.trainingWeekRange == rhs.trainingWeekRange
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(activityType)
        hasher.combine(phaseType)
        hasher.combine(trainingWeekRange)
    }
}
