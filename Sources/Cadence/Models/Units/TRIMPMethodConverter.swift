//
//  TRIMPMethodConverter.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Non-linear converter between different TRIMP calculation methods
///
/// This converter uses intensity-weighted minutes as the base unit, allowing conversion
/// between different TRIMP methods by normalizing through the underlying heart rate intensity
/// that produced the TRIMP value.
public class TRIMPMethodConverter: UnitConverter, @unchecked Sendable {
    
    public enum TRIMPMethod: String, CaseIterable {
        case banister = "banister"
        case edwards = "edwards"
        case lucia = "lucia"
        case trainingLoad = "trainingLoad"
    }
    
    private let method: TRIMPMethod
    
    public init(_ method: TRIMPMethod) {
        self.method = method
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Convert from specific TRIMP method to intensity-weighted minutes (base unit)
    public override func baseUnitValue(fromValue value: Double) -> Double {
        switch method {
        case .banister:
            return normalizeFromBanister(value)
        case .edwards:
            return normalizeFromEdwards(value)
        case .lucia:
            return normalizeFromLucia(value)
        case .trainingLoad:
            return normalizeFromTrainingLoad(value)
        }
    }
    
    /// Convert from intensity-weighted minutes (base unit) to specific TRIMP method
    public override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        switch method {
        case .banister:
            return denormalizeToBanister(baseUnitValue)
        case .edwards:
            return denormalizeToEdwards(baseUnitValue)
        case .lucia:
            return denormalizeToLucia(baseUnitValue)
        case .trainingLoad:
            return denormalizeToTrainingLoad(baseUnitValue)
        }
    }
    
    // MARK: - Normalization Functions (TRIMP → Intensity Minutes)
    
    /// Convert Banister TRIMP to intensity-weighted minutes
    /// Inverse of: Duration × HRr × 0.64 × e^(1.92 × HRr)
    /// Approximation based on typical workout intensity distributions
    private func normalizeFromBanister(_ trimp: Double) -> Double {
        // For moderate intensity (HRr ≈ 0.6): TRIMP ≈ Duration × 0.6 × 0.64 × e^(1.92 × 0.6) ≈ Duration × 3.0
        // So: Duration ≈ TRIMP / 3.0, and intensity minutes ≈ Duration × average_intensity
        // Assuming average intensity of 0.65 for typical workouts
        let estimatedDuration = trimp / 3.0
        let estimatedIntensity = 0.65
        return estimatedDuration * estimatedIntensity * 100 // Scale to reasonable base unit range
    }
    
    /// Convert Edwards TRIMP to intensity-weighted minutes
    /// Edwards zones: 1×(50-60%), 2×(60-70%), 3×(70-80%), 4×(80-90%), 5×(90-100%)
    private func normalizeFromEdwards(_ trimp: Double) -> Double {
        // Edwards TRIMP is essentially duration × average_zone_multiplier
        // Average zone multiplier for typical workout ≈ 2.5
        // So: Duration ≈ TRIMP / 2.5
        let estimatedDuration = trimp / 2.5
        let estimatedIntensity = 0.65 // Corresponding to average zone multiplier
        return estimatedDuration * estimatedIntensity * 100
    }
    
    /// Convert Lucia TRIMP to intensity-weighted minutes
    /// Lucia zones: 1×(below VT1), 2×(VT1-VT2), 3×(above VT2)
    private func normalizeFromLucia(_ trimp: Double) -> Double {
        // Lucia TRIMP average multiplier ≈ 2.0 for typical workouts
        let estimatedDuration = trimp / 2.0
        let estimatedIntensity = 0.65
        return estimatedDuration * estimatedIntensity * 100
    }
    
    /// Convert Training Load ratio to intensity-weighted minutes
    /// This is tricky since it's a ratio, not absolute load
    private func normalizeFromTrainingLoad(_ ratio: Double) -> Double {
        // Training load ratio represents acute:chronic
        // Convert to equivalent weekly intensity minutes
        // Assuming baseline of ~300 intensity minutes per week for ratio = 1.0
        return ratio * 300
    }
    
    // MARK: - Denormalization Functions (Intensity Minutes → TRIMP)
    
    /// Convert intensity-weighted minutes to Banister TRIMP
    private func denormalizeToBanister(_ intensityMinutes: Double) -> Double {
        let estimatedDuration = intensityMinutes / (0.65 * 100)
        // Reverse of: Duration × HRr × 0.64 × e^(1.92 × HRr)
        // For HRr ≈ 0.6: multiplier ≈ 3.0
        return estimatedDuration * 3.0
    }
    
    /// Convert intensity-weighted minutes to Edwards TRIMP
    private func denormalizeToEdwards(_ intensityMinutes: Double) -> Double {
        let estimatedDuration = intensityMinutes / (0.65 * 100)
        // Edwards average multiplier ≈ 2.5
        return estimatedDuration * 2.5
    }
    
    /// Convert intensity-weighted minutes to Lucia TRIMP
    private func denormalizeToLucia(_ intensityMinutes: Double) -> Double {
        let estimatedDuration = intensityMinutes / (0.65 * 100)
        // Lucia average multiplier ≈ 2.0
        return estimatedDuration * 2.0
    }
    
    /// Convert intensity-weighted minutes to Training Load ratio
    private func denormalizeToTrainingLoad(_ intensityMinutes: Double) -> Double {
        // Convert back to ratio based on baseline
        return intensityMinutes / 300
    }
}

/// Polynomial converter for more accurate TRIMP conversions
/// Uses empirical fitting between methods
public class PolynomialTRIMPConverter: UnitConverter, @unchecked Sendable {
    
    private let coefficients: [Double]
    private let method: TRIMPMethodConverter.TRIMPMethod
    
    /// Initialize with polynomial coefficients for conversion
    /// - Parameters:
    ///   - method: Target TRIMP method
    ///   - coefficients: Polynomial coefficients [a₀, a₁, a₂, ...] for y = a₀ + a₁x + a₂x² + ...
    public init(method: TRIMPMethodConverter.TRIMPMethod, coefficients: [Double]) {
        self.method = method
        self.coefficients = coefficients
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func baseUnitValue(fromValue value: Double) -> Double {
        // Convert using polynomial: result = a₀ + a₁x + a₂x² + ...
        var result = 0.0
        for (index, coefficient) in coefficients.enumerated() {
            result += coefficient * pow(value, Double(index))
        }
        return result
    }
    
    public override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        // For reverse conversion, use inverse polynomial (approximation)
        // This is complex for high-order polynomials, so we use iterative approach
        return inversePolynomial(baseUnitValue)
    }
    
    private func inversePolynomial(_ targetValue: Double) -> Double {
        // Newton-Raphson method to find x where f(x) = targetValue
        var x = targetValue // Initial guess
        let maxIterations = 100
        let tolerance = 1e-6
        
        for _ in 0..<maxIterations {
            let fx = evaluatePolynomial(x) - targetValue
            let fpx = evaluatePolynomialDerivative(x)
            
            if abs(fx) < tolerance { break }
            if abs(fpx) < tolerance { break } // Avoid division by zero
            
            x = x - fx / fpx
        }
        
        return x
    }
    
    private func evaluatePolynomial(_ x: Double) -> Double {
        var result = 0.0
        for (index, coefficient) in coefficients.enumerated() {
            result += coefficient * pow(x, Double(index))
        }
        return result
    }
    
    private func evaluatePolynomialDerivative(_ x: Double) -> Double {
        var result = 0.0
        for (index, coefficient) in coefficients.enumerated() where index > 0 {
            result += Double(index) * coefficient * pow(x, Double(index - 1))
        }
        return result
    }
}