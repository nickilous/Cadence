//
//  BanisterTRIMPMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Gender-specific Banister TRIMP calculation using exponential formula
///
/// This implementation uses gender-specific modifications of Banister's formula:
/// - Male: Duration × HRr × 0.64 × e^(1.92 × HRr)
/// - Female: Duration × HRr × 0.86 × e^(1.67 × HRr)
/// where HRr is heart rate reserve calculated as (HRexercise - HRrest) / (HRmax - HRrest)
///
/// The gender-specific coefficients account for physiological differences in cardiovascular
/// response, lactate accumulation patterns, and metabolic stress between males and females.
public struct BanisterTRIMPMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Gender-Specific Banister TRIMP" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
   
    private let athlete: CadenceAthlete?
    
    /// Initialize with athlete profile (fetches HR data and gender from athlete's stores)
    public init(athlete: CadenceAthlete) {
        self.athlete = athlete
    }
    
    public func compute(from store: [CadenceStore], in season: CadenceTrainingSeason) async throws -> Result {
        let supported = store.compactMap { store in
            if (store.supportedActivityTypes.contains(activities) && store.supportedMetricTypes.contains(metrics)) {
                return store
            } else {
                return nil
            }
        }
        
        guard !supported.isEmpty else {
            throw CadenceError.noSupportedActivities(activities)
        }
        
        var sampleMetrics: [any SampleMetric<UnitFrequency>] = []
        
        for store in supported {
            let metric: [any SampleMetric<UnitFrequency>] = try await store.fetch(activities, metrics: metrics, in: season)
            sampleMetrics = sampleMetrics + metric
        }
        
        guard !sampleMetrics.isEmpty else {
            throw CadenceError.noSupportedMetrics(metrics)
        }
        
        // Calculate duration in minutes
        let totalDuration = sampleMetrics.last!.endDate.timeIntervalSince(sampleMetrics.first!.startDate) / 60.0
        
        // Calculate average heart rate
        let totalHR = sampleMetrics.reduce(0.0) { sum, sample in
            sum + sample.measurment.converted(to: .beatsPerMinute).value
        }
        let avgHR = totalHR / Double(sampleMetrics.count)
        
        // Get heart rate parameters and biological gender (from athlete or direct values)
        let restingHR: Double
        let maxHR: Double
        let genderForCalculation: BiologicalGender?
        
        // Fetch from athlete profile (athlete is always non-nil)
        guard let athlete = athlete else {
            throw CadenceError.missingRequiredParameter("Athlete required for BanisterTRIMPMetric")
        }
        
        guard let athleteRestingHR = try await athlete.restingHeartRate,
              let athleteMaxHR = try await athlete.maxHeartRate else {
            throw CadenceError.missingRequiredParameter("Athlete missing resting or max heart rate data")
        }
        
        restingHR = athleteRestingHR
        maxHR = athleteMaxHR
        genderForCalculation = athlete.biologicalGender
        
        // Calculate heart rate reserve
        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
        
        // Validate heart rate reserve is within expected range
        guard hrReserve >= 0 && hrReserve <= 1 else {
            throw CadenceError.missingRequiredParameter("Invalid heart rate data: HRR \(hrReserve) outside valid range (0-1)")
        }
        
        // Apply gender-specific Banister TRIMP formula
        let trimpValue: Double
        
        switch genderForCalculation {
        case .female:
            // Female formula: Duration × HRr × 0.86 × e^(1.67 × HRr)
            trimpValue = totalDuration * hrReserve * 0.86 * exp(1.67 * hrReserve)
        case .male:
            // Male formula: Duration × HRr × 0.64 × e^(1.92 × HRr)
            trimpValue = totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
        case .other, .notSet, .none:
            // Default to male formula when gender is unknown or not specified
            // This maintains backward compatibility and follows research convention
            trimpValue = totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
        }
        
        return SampleMetricContainer<UnitTRIMP>(
            activity: activities,
            metric: .trimp,
            startDate: season.startDate,
            endDate: season.endDate,
            measurment: Measurement(value: trimpValue, unit: UnitTRIMP.BaseUnit())
        )
    }
}
