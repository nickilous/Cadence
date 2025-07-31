//
//  AthleteExample.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Example demonstrating CadenceAthlete usage with TRIMP calculations
public struct AthleteExample {
    
    /// Demonstrates creating an athlete profile and using it for TRIMP calculations
    public static func demonstrateAthleteBasedTRIMP() async throws {
        print("=== Athlete-Based TRIMP Calculation Examples ===\n")
        
        // Create athlete profile with biological data
        let athlete = CadenceAthlete(
            name: "Sarah Runner",
            biologicalGender: .female,
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15))!,
            height: Measurement(value: 168, unit: .centimeters),
            weight: Measurement(value: 62, unit: .kilograms),
            stores: [] // Would normally include HealthKit store, etc.
        )
        
        print("Athlete Profile:")
        print("Name: \(athlete.name ?? "Unknown")")
        print("Gender: \(athlete.biologicalGender?.description ?? "Unknown")")
        print("Age: \(athlete.age ?? 0) years")
        print("Height: \(athlete.height?.formatted() ?? "Unknown")")
        print("Weight: \(athlete.weight?.formatted() ?? "Unknown")")
        if let bmi = athlete.bmi {
            print("BMI: \(String(format: "%.1f", bmi)) (\(athlete.bmiCategory?.description ?? "Unknown"))")
        }
        print()
        
        // Demonstrate heart rate data fetching (would be from real stores)
        print("Heart Rate Data:")
        do {
            if let restingHR = try await athlete.restingHeartRate {
                print("Resting HR: \(Int(restingHR)) bpm")
            }
            if let maxHR = try await athlete.maxHeartRate {
                print("Max HR: \(Int(maxHR)) bpm")
            }
            if let estimatedMaxHR = athlete.estimatedMaxHeartRate {
                print("Estimated Max HR: \(Int(estimatedMaxHR)) bpm (220 - age)")
            }
        } catch {
            print("Heart rate data not available from stores")
            if let estimatedMaxHR = athlete.estimatedMaxHeartRate {
                print("Using estimated Max HR: \(Int(estimatedMaxHR)) bpm (220 - age)")
            }
        }
        print()
        
        // Show training zones
        do {
            if let zones = try await athlete.heartRateZones() {
                print("Heart Rate Training Zones:")
                print("Zone 1 (\(zones.zone1.name)): \(Int(zones.zone1.lowerBound))-\(Int(zones.zone1.upperBound)) bpm")
                print("Zone 2 (\(zones.zone2.name)): \(Int(zones.zone2.lowerBound))-\(Int(zones.zone2.upperBound)) bpm")
                print("Zone 3 (\(zones.zone3.name)): \(Int(zones.zone3.lowerBound))-\(Int(zones.zone3.upperBound)) bpm")
                print("Zone 4 (\(zones.zone4.name)): \(Int(zones.zone4.lowerBound))-\(Int(zones.zone4.upperBound)) bpm")
                print("Zone 5 (\(zones.zone5.name)): \(Int(zones.zone5.lowerBound))-\(Int(zones.zone5.upperBound)) bpm")
            }
        } catch {
            print("Training zones not available (requires heart rate data)")
        }
        print()
        
        // Create TRIMP metrics using athlete profile
        print("TRIMP Calculations with Athlete Profile:")
        
        let banisterTRIMP = BanisterTRIMPMetric(athlete: athlete)
        let edwardsTRIMP = EdwardsTRIMPMetric(athlete: athlete)
        let trainingLoad = TrainingLoadMetric(athlete: athlete)
        
        print("✓ Banister TRIMP metric created with athlete profile")
        print("✓ Edwards TRIMP metric created with athlete profile") 
        print("✓ Training Load metric created with athlete profile")
        print()
        
        // Note: Lucia TRIMP still requires manual parameters
        let luciaTRIMP = LuciaTRIMPMetric(lactateThreshold1: 150, lactateThreshold2: 170)
        print("ℹ️  Lucia TRIMP requires manual lactate thresholds (not available from stores)")
        print()
        
        // Show comparison with manual parameter approach
        print("Comparison: Athlete-based vs Manual Parameters")
        print()
        
        print("Before (Manual Parameters):")
        print("let banister = BanisterTRIMPMetric(restingHeartRate: 50, maxHeartRate: 185)")
        print("let edwards = EdwardsTRIMPMetric(maxHeartRate: 185)")
        print()
        
        print("After (Athlete-based):")
        print("let athlete = CadenceAthlete(name: \"Sarah\", stores: [healthStore])")
        print("let banister = BanisterTRIMPMetric(athlete: athlete)")
        print("let edwards = EdwardsTRIMPMetric(athlete: athlete)")
        print()
        
        print("Benefits:")
        print("• Automatic heart rate data fetching from stores")
        print("• Centralized athlete profile")
        print("• Age-based estimates when store data unavailable")
        print("• Training zone calculations")
        print("• Consistent data across all calculations")
    }
    
    /// Demonstrates using multiple athletes for comparison
    public static func demonstrateMultipleAthletes() async throws {
        print("=== Multiple Athlete Comparison ===\n")
        
        let youngAthlete = CadenceAthlete(
            name: "Alex (22yo)",
            biologicalGender: .male,
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 2002, month: 1, day: 1))!,
            stores: []
        )
        
        let matureAthlete = CadenceAthlete(
            name: "Chris (45yo)",
            biologicalGender: .female,
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1979, month: 1, day: 1))!,
            stores: []
        )
        
        let athletes = [youngAthlete, matureAthlete]
        
        print("Age-based Max HR Comparison:")
        for athlete in athletes {
            if let maxHR = athlete.estimatedMaxHeartRate {
                print("\(athlete.name ?? "Unknown"): Estimated Max HR = \(Int(maxHR)) bpm")
            }
        }
        print()
        
        print("Different athletes will have different:")
        print("• Estimated max heart rates (220 - age)")
        print("• Training zones (% of max HR)")
        print("• TRIMP calculations (personalized to their physiology)")
        print("• Recovery recommendations")
    }
    
    /// Demonstrates error handling with athlete data
    public static func demonstrateErrorHandling() async {
        print("=== Error Handling Examples ===\n")
        
        // Athlete with no stores
        let athleteNoStores = CadenceAthlete(
            name: "No Data Athlete",
            stores: []
        )
        
        // Try to create TRIMP metric - will fall back to estimated values or throw error
        let banisterTRIMP = BanisterTRIMPMetric(athlete: athleteNoStores)
        
        print("Created TRIMP metric with athlete who has no stores")
        print("• Will use estimated max HR (220 - age) if age available")
        print("• Will throw error if no resting HR available and no fallback")
        print("• Graceful degradation to estimates when possible")
        print()
        
        // Show backwards compatibility
        print("Backwards Compatibility:")
        print("• Old parameter-based initializers still work")
        print("• Can mix athlete-based and parameter-based metrics")
        print("• Gradual migration possible")
        
        let manualBanister = BanisterTRIMPMetric(restingHeartRate: 50, maxHeartRate: 185)
        let athleteBanister = BanisterTRIMPMetric(athlete: athleteNoStores)
        
        print("✓ Manual parameters: BanisterTRIMPMetric(restingHeartRate:maxHeartRate:)")
        print("✓ Athlete-based: BanisterTRIMPMetric(athlete:)")
    }
}