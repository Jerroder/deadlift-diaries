//
//  TimerWidgetBundle.swift
//  TimerWidget
//
//  Created by Jerroder on 2026-01-26.
//

import WidgetKit
import SwiftUI

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidgetControl()
        TimerWidgetLiveActivity()
    }
}
