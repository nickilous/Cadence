//
//  UnitFrequency+HeartRate.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public extension UnitFrequency {
    static let beatsPerMinute = UnitFrequency(symbol: "bpm", converter: UnitConverterLinear(coefficient: 1.0 / 60.0))
}