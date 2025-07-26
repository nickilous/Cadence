//
//  Sample.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/8/25.
//

import Foundation

public protocol Sample: Identifiable, Hashable {
    var startDate: Date { get }
    var endDate: Date { get }
}

