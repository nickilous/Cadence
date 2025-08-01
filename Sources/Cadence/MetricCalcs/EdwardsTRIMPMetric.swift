//
//  EdwardsTRIMPMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Edwards' zone-based TRIMP calculation using 5 heart rate zones
///
/// This implementation uses Edwards' 1993 method with 5 zones based on %HRmax:
/// Zone 1 (50-60%): multiplier 1, Zone 2 (60-70%): multiplier 2, Zone 3 (70-80%): multiplier 3,
/// Zone 4 (80-90%): multiplier 4, Zone 5 (90-100%): multiplier 5
/// TRIMP = Σ(time in zone × zone multiplier)
public struct EdwardsTRIMPMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Edwards TRIMP" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let maxHeartRate: Double?
    private let athlete: CadenceAthlete?
    
    
    /// Initialize with athlete profile (fetches max HR from athlete's stores)
    public init(athlete: CadenceAthlete) {
        self.athlete = athlete
        self.maxHeartRate = nil
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
        
        // Get max heart rate (from athlete or direct value)
        let maxHR: Double
        
        if let athlete = athlete {
            // Fetch from athlete profile
            guard let athleteMaxHR = try await athlete.maxHeartRate else {
                throw CadenceError.missingRequiredParameter("Athlete missing max heart rate data")
            }
            maxHR = athleteMaxHR
        } else {
            // Use provided parameter
            guard let maxHeartRate = maxHeartRate else {
                throw CadenceError.missingRequiredParameter("Max heart rate required")
            }
            maxHR = maxHeartRate
        }
        
        // Edwards zones and multipliers
        var timeInZones = [0.0, 0.0, 0.0, 0.0, 0.0] // Zone 1-5
        let zoneMultipliers = [1.0, 2.0, 3.0, 4.0, 5.0]
        
        // Calculate time in each zone
        for i in 0..<(sampleMetrics.count - 1) {
            let currentSample = sampleMetrics[i]
            let nextSample = sampleMetrics[i + 1]
            
            let hr = currentSample.measurment.converted(to: .beatsPerMinute).value
            let hrPercent = hr / maxHR
            let duration = nextSample.startDate.timeIntervalSince(currentSample.startDate) / 60.0
            
            // Determine zone (50-60%, 60-70%, 70-80%, 80-90%, 90-100%)
            let zoneIndex: Int
            switch hrPercent {
            case 0.5..<0.6: zoneIndex = 0
            case 0.6..<0.7: zoneIndex = 1
            case 0.7..<0.8: zoneIndex = 2
            case 0.8..<0.9: zoneIndex = 3
            case 0.9...1.0: zoneIndex = 4
            default: continue // Skip samples outside defined zones
            }
            
            timeInZones[zoneIndex] += duration
        }
        
        // Calculate weighted sum: TRIMP = Σ(time in zone × zone multiplier)
        let trimpValue = zip(timeInZones, zoneMultipliers).reduce(0.0) { result, pair in
            result + (pair.0 * pair.1)
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
