//
//  SampleWorkout.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/18/25.
//

import Foundation

public protocol SampleWorkout: Sample {
    var activityType: ActivityOptions { get }
}
