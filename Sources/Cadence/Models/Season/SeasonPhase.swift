//
//  TrainingPhase.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public enum CadencePhaseType : CaseIterable, Sendable {
    case base
    case building
    case peak
}

public struct CadenceTrainingPhase: Identifiable, Hashable, Sendable {
    public var id: UUID = .init()
    public var activityType: ActivityOptions
    public var phaseType: CadencePhaseType
    public var trainingWeekRange: CadenceTrainingWeekRange
    
    public init(id: UUID, activityType: ActivityOptions, phaseType: CadencePhaseType, trainingWeekRange: CadenceTrainingWeekRange) {
        self.id = id
        self.activityType = activityType
        self.phaseType = phaseType
        self.trainingWeekRange = trainingWeekRange
    }
    
    public static func == (lhs: CadenceTrainingPhase, rhs: CadenceTrainingPhase) -> Bool {
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
