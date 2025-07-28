//
//  TrainingSeason.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation


public typealias CadenceTrainingWeekRange = ClosedRange<CadenceTrainingWeekMarker>


public struct CadenceTrainingSeason: Identifiable, Hashable {
    public var id: UUID = .init()
    public var seasonInterval: CadenceTrainingWeekRange
    public var trainingPhases: [CadenceTrainingPhase]
    
    public init(id: UUID = UUID(), seasonInterval: CadenceTrainingWeekRange, @SeasonPhaseBuilder builder: () -> [CadenceTrainingPhase]) {
        self.id = id
        self.seasonInterval = seasonInterval
        self.trainingPhases = builder()
    }
}

extension CadenceTrainingSeason: DateRangeComponent {
    public var startDate: Date { seasonInterval.startDate }
    public var endDate: Date { seasonInterval.endDate }
}

public var trainingSeason: CadenceTrainingSeason {
    .init(seasonInterval: CadenceTrainingWeekRange(startDate: Date.now, endDate: Date.now)) {
        CadenceTrainingPhase(id: UUID(),
                      activityType: ActivityOptions.running,
                      phaseType: CadencePhaseType.building,
                      trainingWeekRange: CadenceTrainingWeekRange(startDate: Date.now, endDate: Date.now))
        CadenceTrainingPhase(id: UUID(),
                      activityType: ActivityOptions.strength,
                      phaseType: CadencePhaseType.building,
                      trainingWeekRange: CadenceTrainingWeekRange(startDate: Date.now, endDate: Date.now))
    }
}

