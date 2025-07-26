//
//  MetricTargetComponent.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

public struct MetricTargetComponent: QueryComponent {
    public var id: UUID = .init()
    public var metricTarget: MetricOptions
}
