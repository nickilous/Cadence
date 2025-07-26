//
//  MetricTargetComponentBuilder.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

@resultBuilder
public enum MetricTargetComponentBuilder {
    public static func buildBlock(_ components: MetricTargetComponent...) -> [MetricTargetComponent] {
        components
    }
}
