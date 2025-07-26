//
//  AuthorizationOptions.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation

public struct AuthorizationOption: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public static let read = AuthorizationOption(rawValue: 1 << 0)
    public static let write = AuthorizationOption(rawValue: 1 << 1)
    public static let both = [read, write]
}
