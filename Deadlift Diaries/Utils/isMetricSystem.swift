//
//  isMetricSystem.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import SwiftUI

func isMetricSystem() -> Bool {
    let locale: Locale = Locale.current
    switch locale.measurementSystem {
    case .metric:
        return true

    case .us: fallthrough
    case .uk:
        return false

    default:
        return false
    }
}

func distanceUnit() -> Unit {
    // I know meters and miles don't compare but they should just use SI like everyone else
    isMetricSystem() ? Unit(symbol: "m") : Unit(symbol: "mi")
}
