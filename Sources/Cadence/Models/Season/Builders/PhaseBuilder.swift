//
//  PhaseBuilder.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation


@resultBuilder
public enum SeasonPhaseBuilder {
    public static func buildBlock(_ phases: CadenceTrainingPhase...) -> [CadenceTrainingPhase] {
        phases
    }
}
