//
//  TargetComponent.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

public struct ActivityTargetComponent: QueryComponent {
    public var id: UUID = .init()
    public var activityTarget: ActivityOptions
    public var metrics: [MetricTargetComponent]
    
    public init(id: UUID, activityTarget: ActivityOptions, @MetricTargetComponentBuilder metrics: () -> [MetricTargetComponent] ) {
        self.id = id
        self.activityTarget = activityTarget
        self.metrics = metrics()
    }
}


