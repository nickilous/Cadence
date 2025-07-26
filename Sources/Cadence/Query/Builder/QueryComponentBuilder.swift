//
//  QueryComponentBuilder.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/14/25.
//

import Foundation

@resultBuilder
public enum QueryComponentBuilder {
    public static func buildBlock(_ components: any QueryComponent...) -> [any QueryComponent] {
        return components
    }
}
