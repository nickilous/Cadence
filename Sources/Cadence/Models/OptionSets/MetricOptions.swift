//
//  MetricType.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public struct MetricOptions: OptionSet, Hashable, CustomStringConvertible, Sendable {
    public let rawValue: Int64
    
    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }
    
    //Vitals
    public static let heartRate = MetricOptions(rawValue: 1 << 0)
    public static let restingHeartRate = MetricOptions(rawValue: 1 << 1)
    public static let heartVariability = MetricOptions(rawValue: 1 << 2)
    public static let walkingHeartRateAverage = MetricOptions(rawValue: 1 << 3)
    public static let heartRateRecoveryOneMinute = MetricOptions(rawValue: 1 << 4)
    
    //Activity
    public static let runningPower = MetricOptions(rawValue: 1 << 5)
    public static let runningGroundContactTime = MetricOptions(rawValue: 1 << 6)
    public static let runningSpeed = MetricOptions(rawValue: 1 << 7)
    public static let runningStrideLength = MetricOptions(rawValue: 1 << 8)
    public static let runningVerticalOscillation = MetricOptions(rawValue: 1 << 9)
    public static let distanceWalkingRunning = MetricOptions(rawValue: 1 << 10)
    public static let distanceCycling = MetricOptions(rawValue: 1 << 11)
    
    //Energy
    public static let basalEnergyBurned = MetricOptions(rawValue: 1 << 12)
    public static let activeEnergyBurned = MetricOptions(rawValue: 1 << 13)
    
    //Training Load
    public static let trimp = MetricOptions(rawValue: 1 << 14)
    
    
    public static let all = MetricOptions([
        .heartRate,
        .restingHeartRate,
        .heartVariability,
        .walkingHeartRateAverage,
        .heartRateRecoveryOneMinute,
        .runningPower,
        .runningGroundContactTime,
        .runningSpeed,
        .runningStrideLength,
        .runningVerticalOscillation,
        .distanceWalkingRunning,
        .distanceCycling,
        .basalEnergyBurned,
        .activeEnergyBurned,
        .trimp])
    
    public var description: String {
        switch self {
        case .activeEnergyBurned: return "Active Energy Burned"
        case .basalEnergyBurned: return "Basal Energy Burned"
        case .distanceCycling: return "Distance Cycling"
        case .distanceWalkingRunning: return "Distance Walking Running"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .runningGroundContactTime: return "Running Ground Contact Time"
        case .runningPower: return "Running Power"
        case .runningSpeed: return "Running Speed"
        case .runningStrideLength: return "Running Stride Length"
        case .runningVerticalOscillation: return "Running Vertical Oscillation"
        case .walkingHeartRateAverage: return "Walking Heart Rate Average"
        case .trimp: return "Training Impulse (TRIMP)"
        default : return "Unknown"
        }
    }
}

