//
//  ActivityType.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/7/25.
//

import Foundation

public struct ActivityOptions: OptionSet, Hashable, CustomStringConvertible, Sendable {
    public let rawValue: Int64
    
    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }
    
    public static let running = ActivityOptions(rawValue: 1 << 0)
    public static let cycling = ActivityOptions(rawValue: 1 << 1)
    public static let swimming = ActivityOptions(rawValue: 1 << 2)
    public static let strength = ActivityOptions(rawValue: 1 << 3)
    public static let functional = ActivityOptions(rawValue: 1 << 4)
    public static let yoga = ActivityOptions(rawValue: 1 << 5)
    public static let core = ActivityOptions(rawValue: 1 << 6)
    
    public static let dayToDay = ActivityOptions(rawValue: 1 << 7)
    
    public static let all = ActivityOptions([.running, .cycling, .swimming, .strength, .functional, .yoga, .core, .dayToDay])
    
    public var description: String {
        switch self {
        case .cycling: return "Cycling"
        case .functional: return "Functional"
        case .running: return "Running"
        case .strength: return "Strength"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .core: return "Core"
        default : return "Unknown"
        }
    }
}

