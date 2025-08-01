//
//  TrainingLoadMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Training Load metric calculating Acute:Chronic workload ratio with gender-specific TRIMP
///
/// This implementation calculates the ratio between acute load (7-day average TRIMP) 
/// and chronic load (28-day average TRIMP) using gender-specific Banister's TRIMP formulas.
/// Ratios between 0.8-1.3 are considered optimal training zones.
///
/// Uses gender-specific coefficients:
/// - Male: Duration × HRr × 0.64 × e^(1.92 × HRr)
/// - Female: Duration × HRr × 0.86 × e^(1.67 × HRr)
public struct TrainingLoadMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Gender-Specific Training Load (A:C Ratio)" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let athlete: CadenceAthlete?
    private let banisterTRIMP: BanisterTRIMPMetric
    private let acuteDays: Int = 7
    private let chronicDays: Int = 28
    
    /// Initialize with athlete profile (fetches HR data and gender from athlete's stores)
    public init(athlete: CadenceAthlete) {
        self.athlete = athlete
        self.banisterTRIMP = BanisterTRIMPMetric(athlete: athlete)
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
        
        // Athlete validation (athlete is always non-nil)
        guard athlete != nil else {
            throw CadenceError.missingRequiredParameter("Athlete required for TrainingLoadMetric")
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
            
            // Calculate TRIMP for this day using BanisterTRIMPMetric
            do {
                let dayTRIMPResult = try await banisterTRIMP.compute(from: supported, in: daySeason)
                let dayTRIMP = dayTRIMPResult.measurment.value
                dailyTRIMPs.append(dayTRIMP)
            } catch {
                // No data for this day, TRIMP = 0
                dailyTRIMPs.append(0.0)
            }
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