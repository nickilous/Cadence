//
//  TrainingQuery.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

public struct TrainingQuery: Identifiable, Sendable {
    public var id: UUID = .init()
    public var components: [any QueryComponent]
    
    public init(id: UUID, @QueryComponentBuilder components: () -> [any QueryComponent]) {
        self.id = id
        self.components = components()
    }
}


public let trainingQuery: TrainingQuery = .init(id: .init()) {
    TrainingSeason(seasonInterval: .init(startDate: .now, endDate: .now)) {
        TrainingPhase(id: .init(),
                      activityType: .running,
                      phaseType: .building,
                      trainingWeekRange: .init(startDate: .now, endDate: .now))
    }
    ActivityTargetComponent(id: .init(), activityTarget: .running) {
        MetricTargetComponent(id: .init(), metricTarget: .activeEnergyBurned)
        MetricTargetComponent(metricTarget: .heartRate)
    }
    
}
