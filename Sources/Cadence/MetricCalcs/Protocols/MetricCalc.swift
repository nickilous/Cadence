//
//  MetricCalc.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation


/// Protocol for implementing fitness metric calculations
///
/// Conforming types define how to compute specific metrics (like average power, heart rate zones, etc.)
/// from raw activity data. Each metric declares its data dependencies and units.
public protocol CadenceMetricCalc: Identifiable, CustomStringConvertible, Hashable, Sendable {
    associatedtype Result: Sample
    func compute(from store: [CadenceStore], in season: CadenceTrainingSeason) async throws -> Result
}


extension CadenceMetricCalc {
    
}
