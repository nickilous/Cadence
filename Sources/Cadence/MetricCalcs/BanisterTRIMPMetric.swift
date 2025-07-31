//
//  BanisterTRIMPMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Banister's original TRIMP calculation using exponential formula
///
/// This implementation uses Banister's 1975 formula: Duration × HRr × 0.64 × e^(1.92 × HRr)
/// where HRr is heart rate reserve calculated as (HRexercise - HRrest) / (HRmax - HRrest)
public struct BanisterTRIMPMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Banister TRIMP" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let restingHeartRate: Double?
    private let maxHeartRate: Double?
    private let athlete: CadenceAthlete?
    
    /// Initialize with specific heart rate parameters
    public init(restingHeartRate: Double, maxHeartRate: Double) {
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.athlete = nil
    }
    
    /// Initialize with athlete profile (fetches HR data from athlete's stores)
    public init(athlete: CadenceAthlete) {
        self.restingHeartRate = nil
        self.maxHeartRate = nil
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
        
        // Get heart rate parameters (from athlete or direct values)
        let restingHR: Double
        let maxHR: Double
        
        if let athlete = athlete {
            // Fetch from athlete profile
            guard let athleteRestingHR = try await athlete.restingHeartRate,
                  let athleteMaxHR = try await athlete.maxHeartRate else {
                throw CadenceError.missingRequiredParameter("Athlete missing resting or max heart rate data")
            }
            restingHR = athleteRestingHR
            maxHR = athleteMaxHR
        } else {
            // Use provided parameters
            guard let restingHeartRate = restingHeartRate,
                  let maxHeartRate = maxHeartRate else {
                throw CadenceError.missingRequiredParameter("Resting and max heart rate required")
            }
            restingHR = restingHeartRate
            maxHR = maxHeartRate
        }
        
        // Calculate heart rate reserve
        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
        
        // Banister's TRIMP formula: Duration × HRr × 0.64 × e^(1.92 × HRr)
        let trimpValue = totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
        
        return SampleMetricContainer<UnitTRIMP>(
            activity: activities,
            metric: .trimp,
            startDate: season.startDate,
            endDate: season.endDate,
            measurment: Measurement(value: trimpValue, unit: UnitTRIMP.BaseUnit())
        )
    }
}