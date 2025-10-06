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
