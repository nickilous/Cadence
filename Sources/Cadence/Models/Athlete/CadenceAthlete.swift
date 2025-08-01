//
//  CadenceAthlete.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Biological gender for fitness and physiological calculations
public enum BiologicalGender: String, CaseIterable, Sendable {
    case male = "male"
    case female = "female" 
    case other = "other"
    case notSet = "not set"
    
    public var description: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .notSet: return "Not Set"
        }
    }
}

public enum MeasurementSystem {
    case metric
    case imperial
}

/// Represents an athlete with biological and physiological characteristics
///
/// The athlete model centralizes athlete-specific data needed for fitness calculations,
/// automatically fetching physiological metrics from connected stores while storing
/// user-provided biological information.
public struct CadenceAthlete: Identifiable, Hashable, Sendable {
    
    // MARK: - Identity
    
    public let id: UUID
    public let name: String?
    
    // MARK: - Biological Properties
    
    public var biologicalGender: BiologicalGender? {
        let store = stores.first { store in
            store.supportedMetricTypes.contains(.biologicalGender)
        }
        return store?.biologicalGender
    }
    
    public var height: Measurement<UnitLength>? {
        get async {
            let store = stores.first { store in
                store.supportedMetricTypes.contains(.height)
            }
            return await store?.currentHeight
        }
    }
    public var weight: Measurement<UnitMass>? {
        get async {
            let store = stores.first { store in
                store.supportedMetricTypes.contains(.weight)
            }
            return await store?.currentWeight
        }
    }
    
    // MARK: - Data Sources
    
    let stores: [CadenceStore]
    
    // MARK: - Initialization
    
    public init(name: String, stores: [CadenceStore]) {
        self.id = UUID()
        self.name = name
        self.stores = stores
    }
    
    // MARK: - Computed Properties
    
    /// Calculate age from date of birth
    public var age: Int? {
        let store = stores.first { store in
            store.supportedMetricTypes.contains(.age)
        }
        return store?.age
    }
    
    /// Calculate BMI from height and weight
    public var bmi: Double? {
        get async {
            guard let height = await height?.converted(to: .meters).value,
                  let weight = await weight?.converted(to: .kilograms).value,
                  height > 0 else { return nil }
            
            return weight / (height * height)
        }
    }
    
    /// BMI category based on standard ranges
    public var bmiCategory: BMICategory? {
        get async {
            guard let bmi = await bmi else { return nil }
            
            switch bmi {
            case ..<18.5: return .underweight
            case 18.5..<25.0: return .normal
            case 25.0..<30.0: return .overweight
            default: return .obese
            }
        }
    }
    
    // MARK: - Physiological Data (Store-Fetched)
    
    /// Fetch resting heart rate from connected stores
    public var restingHeartRate: Double? {
        get async throws {
            // Create a recent time range (last 30 days)
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
            let season = CadenceTrainingSeason(
                seasonInterval: CadenceTrainingWeekRange(startDate: startDate, endDate: endDate)
            ) {}
            
            // Find stores that support resting heart rate
            let supportedStores = stores.filter { store in
                store.supportedMetricTypes.contains(.restingHeartRate)
            }
            
            guard !supportedStores.isEmpty else { return nil }
            
            // Fetch resting heart rate data
            var allSamples: [SampleMetricContainer<UnitFrequency>] = []
            for store in supportedStores {
                let samples: [SampleMetricContainer<UnitFrequency>] = try await store.fetch(
                    .all, // Any activity type
                    metrics: .restingHeartRate,
                    in: season
                )
                allSamples.append(contentsOf: samples)
            }
            
            guard !allSamples.isEmpty else { return nil }
            
            // Return most recent resting heart rate
            let sortedSamples = allSamples.sorted { $0.startDate > $1.startDate }
            return sortedSamples.first?.measurment.converted(to: .beatsPerMinute).value
        }
    }
    
    /// Calculate maximum heart rate from historical data
    public var maxHeartRate: Double? {
        get async throws {
            // Look at last 6 months of data for max HR
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate)!
            let season = CadenceTrainingSeason(
                seasonInterval: CadenceTrainingWeekRange(startDate: startDate, endDate: endDate)
            ) {}
            
            // Find stores that support heart rate
            let supportedStores = stores.filter { store in
                store.supportedMetricTypes.contains(.heartRate)
            }
            
            guard !supportedStores.isEmpty else {
                // Fallback to age-based estimate if no data available
                return estimatedMaxHeartRate
            }
            
            // Fetch heart rate data
            var allSamples: [SampleMetricContainer<UnitFrequency>] = []
            for store in supportedStores {
                let samples: [SampleMetricContainer<UnitFrequency>] = try await store.fetch(
                    [.running, .cycling], // High-intensity activities
                    metrics: .heartRate,
                    in: season
                )
                allSamples.append(contentsOf: samples)
            }
            
            guard !allSamples.isEmpty else {
                return estimatedMaxHeartRate
            }
            
            // Find maximum heart rate from data
            let maxHR = allSamples.map { 
                $0.measurment.converted(to: .beatsPerMinute).value 
            }.max()
            
            // Return max from data or age-based estimate, whichever is higher
            if let maxHR = maxHR, let estimated = estimatedMaxHeartRate {
                return max(maxHR, estimated)
            }
            
            return maxHR ?? estimatedMaxHeartRate
        }
    }
    
    /// Age-based maximum heart rate estimate (220 - age)
    public var estimatedMaxHeartRate: Double? {
        guard let age = age else { return nil }
        return 220.0 - Double(age)
    }
    
    // MARK: - Training Zones
    
    /// Calculate heart rate training zones based on max HR
    public func heartRateZones() async throws -> HeartRateZones? {
        guard let maxHR = try await maxHeartRate else { return nil }
        
        return HeartRateZones(
            zone1: HeartRateZone(lowerBound: 0.50 * maxHR, upperBound: 0.60 * maxHR, name: "Recovery"),
            zone2: HeartRateZone(lowerBound: 0.60 * maxHR, upperBound: 0.70 * maxHR, name: "Aerobic Base"),
            zone3: HeartRateZone(lowerBound: 0.70 * maxHR, upperBound: 0.80 * maxHR, name: "Tempo"),
            zone4: HeartRateZone(lowerBound: 0.80 * maxHR, upperBound: 0.90 * maxHR, name: "Lactate Threshold"),
            zone5: HeartRateZone(lowerBound: 0.90 * maxHR, upperBound: 1.00 * maxHR, name: "VO2 Max")
        )
    }
}

// MARK: - Supporting Types

/// BMI category classifications
public enum BMICategory: String, CaseIterable {
    case underweight = "underweight"
    case normal = "normal"
    case overweight = "overweight"
    case obese = "obese"
    
    public var description: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal: return "Normal Weight"
        case .overweight: return "Overweight"
        case .obese: return "Obese"
        }
    }
}

/// Heart rate training zone
public struct HeartRateZone: Hashable, Sendable {
    public let lowerBound: Double // BPM
    public let upperBound: Double // BPM
    public let name: String
    
    public init(lowerBound: Double, upperBound: Double, name: String) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.name = name
    }
    
    /// Check if a heart rate falls within this zone
    public func contains(_ heartRate: Double) -> Bool {
        return heartRate >= lowerBound && heartRate <= upperBound
    }
}

/// Complete heart rate zone system
public struct HeartRateZones: Hashable, Sendable {
    public let zone1: HeartRateZone // 50-60%
    public let zone2: HeartRateZone // 60-70%
    public let zone3: HeartRateZone // 70-80%
    public let zone4: HeartRateZone // 80-90%
    public let zone5: HeartRateZone // 90-100%
    
    public init(zone1: HeartRateZone, zone2: HeartRateZone, zone3: HeartRateZone, zone4: HeartRateZone, zone5: HeartRateZone) {
        self.zone1 = zone1
        self.zone2 = zone2
        self.zone3 = zone3
        self.zone4 = zone4
        self.zone5 = zone5
    }
    
    /// Get all zones as an array
    public var allZones: [HeartRateZone] {
        [zone1, zone2, zone3, zone4, zone5]
    }
    
    /// Determine which zone a heart rate falls into
    public func zoneFor(heartRate: Double) -> HeartRateZone? {
        return allZones.first { $0.contains(heartRate) }
    }
}

// MARK: - CadenceAthlete Hashable/Equatable Conformance

extension CadenceAthlete {
    /// Manual Hashable conformance (excludes stores since they can't be hashed)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        // Note: stores are excluded from hashing since CadenceStore is not Hashable
    }
    
    /// Manual Equatable conformance (excludes stores since they can't be compared)
    public static func == (lhs: CadenceAthlete, rhs: CadenceAthlete) -> Bool {
        return lhs.id == rhs.id
        // Note: stores are excluded from equality since CadenceStore is not Equatable
    }
}
