//
//  TrainingSeason.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation


public typealias TrainingWeekRange = ClosedRange<TrainingWeekMarker>


public struct TrainingSeason: Identifiable, Hashable {
    public var id: UUID = .init()
    public var seasonInterval: TrainingWeekRange
    public var trainingPhases: [TrainingPhase]
    
    public init(id: UUID = UUID(), seasonInterval: TrainingWeekRange, @SeasonPhaseBuilder builder: () -> [TrainingPhase]) {
        self.id = id
        self.seasonInterval = seasonInterval
        self.trainingPhases = builder()
    }
}

extension TrainingSeason: DateRangeComponent {
    public var startDate: Date { seasonInterval.startDate }
    public var endDate: Date { seasonInterval.endDate }
}

public var trainingSeason: TrainingSeason {
    .init(seasonInterval: .init(startDate: .now, endDate: .now)) {
        TrainingPhase(id: .init(),
                      activityType: .running,
                      phaseType: .building,
                      trainingWeekRange: .init(startDate: .now, endDate: .now))
        TrainingPhase(id: .init(),
                      activityType: .strength,
                      phaseType: .building,
                      trainingWeekRange: .init(startDate: .now, endDate: .now))
    }
}

