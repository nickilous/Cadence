//
//  UnitTRIMP.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Unit for Training Impulse (TRIMP) measurements
///
/// TRIMP is a dimensionless metric that quantifies training load based on heart rate data.
/// Different calculation methods (Banister, Edwards, Lucia) all produce TRIMP values that
/// can be compared and analyzed over time.
public final class UnitTRIMP: Dimension, @unchecked Sendable {
    
    /// Base unit for TRIMP values (intensity-weighted minutes)
    public static let trimp = UnitTRIMP(symbol: "TRIMP", converter: UnitConverterLinear(coefficient: 1.0))
    
    /// Method-specific TRIMP units with conversion between methods
    public static let banisterTRIMP = UnitTRIMP(symbol: "B-TRIMP", converter: TRIMPMethodConverter(.banister))
    public static let edwardsTRIMP = UnitTRIMP(symbol: "E-TRIMP", converter: TRIMPMethodConverter(.edwards))
    public static let luciaTRIMP = UnitTRIMP(symbol: "L-TRIMP", converter: TRIMPMethodConverter(.lucia))
    public static let trainingLoadRatio = UnitTRIMP(symbol: "TL-Ratio", converter: TRIMPMethodConverter(.trainingLoad))
    
    /// Convenience accessor for base unit
    public class func BaseUnit() -> UnitTRIMP {
        return .trimp
    }
    
    public override class func baseUnit() -> UnitTRIMP {
        return .trimp
    }
}