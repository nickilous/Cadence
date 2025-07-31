//
//  TrainingLoadMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Training Load metric calculating Acute:Chronic workload ratio
///
/// This implementation calculates the ratio between acute load (7-day average TRIMP) 
/// and chronic load (28-day average TRIMP) using Banister's TRIMP formula.
/// Ratios between 0.8-1.3 are considered optimal training zones.
public struct TrainingLoadMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Training Load (A:C Ratio)" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let restingHeartRate: Double
    private let maxHeartRate: Double
    private let acuteDays: Int = 7
    private let chronicDays: Int = 28
    
    public init(restingHeartRate: Double, maxHeartRate: Double) {
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
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
        
        // Calculate daily TRIMP values for the chronic period
        let endDate = season.endDate
        let chronicStart = Calendar.current.date(byAdding: .day, value: -chronicDays, to: endDate)!
        var dailyTRIMPs: [Double] = []
        
        // Calculate TRIMP for each day in the chronic period
        for dayOffset in 0..<chronicDays {
            let dayStart = Calendar.current.date(byAdding: .day, value: dayOffset, to: chronicStart)!
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySeason = CadenceTrainingSeason(seasonInterval: CadenceTrainingWeekRange(startDate: dayStart, endDate: dayEnd)) {}
            
            var dayTRIMP = 0.0
            
            // Fetch heart rate data for this day
            for store in supported {
                do {
                    let dayMetrics: [any SampleMetric<UnitFrequency>] = try await store.fetch(activities, metrics: metrics, in: daySeason)
                    
                    if !dayMetrics.isEmpty {
                        // Calculate Banister TRIMP for this day
                        let totalDuration = dayMetrics.last!.endDate.timeIntervalSince(dayMetrics.first!.startDate) / 60.0
                        let totalHR = dayMetrics.reduce(0.0) { sum, sample in
                            sum + sample.measurment.converted(to: .beatsPerMinute).value
                        }
                        let avgHR = totalHR / Double(dayMetrics.count)
                        let hrReserve = (avgHR - restingHeartRate) / (maxHeartRate - restingHeartRate)
                        
                        dayTRIMP += totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
                    }
                } catch {
                    // No data for this day, TRIMP = 0
                }
            }
            
            dailyTRIMPs.append(dayTRIMP)
        }
        
        // Calculate acute and chronic loads
        let acuteTRIMPs = Array(dailyTRIMPs.suffix(acuteDays))
        let acuteLoad = acuteTRIMPs.reduce(0, +) / Double(acuteDays)
        let chronicLoad = dailyTRIMPs.reduce(0, +) / Double(chronicDays)
        
        // Calculate Acute:Chronic ratio
        let acuteChronicRatio = chronicLoad > 0 ? acuteLoad / chronicLoad : 0.0
        
        return SampleMetricContainer<UnitTRIMP>(
            activity: activities,
            metric: .trimp,
            startDate: season.startDate,
            endDate: season.endDate,
            measurment: Measurement(value: acuteChronicRatio, unit: UnitTRIMP.BaseUnit())
        )
    }
}