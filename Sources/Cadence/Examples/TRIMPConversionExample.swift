//
//  TRIMPConversionExample.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Example demonstrating TRIMP method conversions
public struct TRIMPConversionExample {
    
    /// Demonstrates converting between different TRIMP calculation methods
    public static func demonstrateConversions() {
        print("=== TRIMP Method Conversion Examples ===\n")
        
        // Example workout: 60 minutes at moderate intensity
        // Each method would calculate different TRIMP values for the same workout
        
        // Simulated TRIMP values for the same workout
        let banisterValue = 150.0  // Banister's exponential formula
        let edwardsValue = 100.0   // Edwards' zone-based method
        let luciaValue = 90.0      // Lucia's threshold-based method
        
        // Create measurements using method-specific units
        let banisterMeasurement = Measurement(value: banisterValue, unit: UnitTRIMP.banisterTRIMP)
        let edwardsMeasurement = Measurement(value: edwardsValue, unit: UnitTRIMP.edwardsTRIMP)
        let luciaMeasurement = Measurement(value: luciaValue, unit: UnitTRIMP.luciaTRIMP)
        
        print("Original Values:")
        print("Banister TRIMP: \(banisterMeasurement.formatted())")
        print("Edwards TRIMP: \(edwardsMeasurement.formatted())")
        print("Lucia TRIMP: \(luciaMeasurement.formatted())")
        print()
        
        // Convert Banister to other methods
        let banisterToEdwards = banisterMeasurement.converted(to: .edwardsTRIMP)
        let banisterToLucia = banisterMeasurement.converted(to: .luciaTRIMP)
        
        print("Converting Banister TRIMP to other methods:")
        print("Banister → Edwards: \(banisterToEdwards.formatted())")
        print("Banister → Lucia: \(banisterToLucia.formatted())")
        print()
        
        // Convert Edwards to other methods
        let edwardsToBanister = edwardsMeasurement.converted(to: .banisterTRIMP)
        let edwardsToLucia = edwardsMeasurement.converted(to: .luciaTRIMP)
        
        print("Converting Edwards TRIMP to other methods:")
        print("Edwards → Banister: \(edwardsToBanister.formatted())")
        print("Edwards → Lucia: \(edwardsToLucia.formatted())")
        print()
        
        // Convert all to base intensity-weighted minutes
        let banisterToBase = banisterMeasurement.converted(to: .trimp)
        let edwardsToBase = edwardsMeasurement.converted(to: .trimp)
        let luciaToBase = luciaMeasurement.converted(to: .trimp)
        
        print("Converting to base unit (intensity-weighted minutes):")
        print("Banister → Base: \(banisterToBase.formatted())")
        print("Edwards → Base: \(edwardsToBase.formatted())")
        print("Lucia → Base: \(luciaToBase.formatted())")
        print()
        
        // Demonstrate polynomial converter usage
        demonstratePolynomialConverter()
    }
    
    /// Demonstrates the polynomial converter for more accurate conversions
    private static func demonstratePolynomialConverter() {
        print("=== Polynomial Converter Example ===")
        
        // Example: Convert Edwards to Banister using polynomial fit
        // Coefficients derived from empirical data fitting
        // y = a₀ + a₁x + a₂x² (quadratic fit)
        let edwardsToBanisterCoeffs = [10.0, 1.3, 0.002] // Example coefficients
        
        let polynomialConverter = PolynomialTRIMPConverter(
            method: .banister,
            coefficients: edwardsToBanisterCoeffs
        )
        
        let edwardsUnit = UnitTRIMP(symbol: "E-TRIMP-Poly", converter: polynomialConverter)
        let edwardsMeasurement = Measurement(value: 100.0, unit: edwardsUnit)
        let convertedToBanister = edwardsMeasurement.converted(to: .banisterTRIMP)
        
        print("Polynomial conversion Edwards → Banister: \(convertedToBanister.formatted())")
        print()
    }
    
    /// Usage example in a training context
    public static func trainingAnalysisExample() {
        print("=== Training Analysis with TRIMP Conversions ===")
        
        // Scenario: Athlete uses Edwards TRIMP but wants to compare with research using Banister
        let weeklyEdwardsTRIMP = [120.0, 95.0, 140.0, 110.0, 130.0, 85.0, 160.0] // 7 days
        
        print("Weekly Edwards TRIMP values:")
        for (day, value) in weeklyEdwardsTRIMP.enumerated() {
            let measurement = Measurement(value: value, unit: UnitTRIMP.edwardsTRIMP)
            let banisterEquivalent = measurement.converted(to: .banisterTRIMP)
            print("Day \(day + 1): \(measurement.formatted()) → \(banisterEquivalent.formatted())")
        }
        
        let totalEdwards = weeklyEdwardsTRIMP.reduce(0, +)
        let totalBanister = Measurement(value: totalEdwards, unit: UnitTRIMP.edwardsTRIMP)
            .converted(to: .banisterTRIMP).value
        
        print("Weekly totals: Edwards \(totalEdwards), Banister equivalent \(String(format: "%.1f", totalBanister))")
    }
}