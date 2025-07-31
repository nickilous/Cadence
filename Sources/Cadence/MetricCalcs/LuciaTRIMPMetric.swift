//
//  LuciaTRIMPMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Lucia's threshold-based TRIMP calculation using 3 physiological zones
///
/// This implementation uses Lucia's 2003 method with 3 zones based on lactate thresholds:
/// Zone 1: Below VT1 (aerobic threshold), multiplier 1
/// Zone 2: Between VT1 and VT2 (lactate threshold), multiplier 2  
/// Zone 3: Above VT2 (anaerobic), multiplier 3
/// TRIMP = Σ(time in zone × zone multiplier)
public struct LuciaTRIMPMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Lucia TRIMP" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let lactateThreshold1: Double // VT1 - aerobic threshold
    private let lactateThreshold2: Double // VT2 - lactate threshold
    
    public init(lactateThreshold1: Double, lactateThreshold2: Double) {
        self.lactateThreshold1 = lactateThreshold1
        self.lactateThreshold2 = lactateThreshold2
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
        
        // Lucia's 3 zones with multipliers
        var timeInZones = [0.0, 0.0, 0.0] // Zone 1, 2, 3
        let zoneMultipliers = [1.0, 2.0, 3.0]
        
        // Calculate time in each physiological zone
        for i in 0..<(sampleMetrics.count - 1) {
            let currentSample = sampleMetrics[i]
            let nextSample = sampleMetrics[i + 1]
            
            let hr = currentSample.measurment.converted(to: .beatsPerMinute).value
            let duration = nextSample.startDate.timeIntervalSince(currentSample.startDate) / 60.0
            
            // Determine zone based on lactate thresholds
            let zoneIndex: Int
            if hr < lactateThreshold1 {
                zoneIndex = 0 // Below VT1 (aerobic)
            } else if hr < lactateThreshold2 {
                zoneIndex = 1 // Between VT1 and VT2
            } else {
                zoneIndex = 2 // Above VT2 (anaerobic)
            }
            
            timeInZones[zoneIndex] += duration
        }
        
        // Calculate weighted sum
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