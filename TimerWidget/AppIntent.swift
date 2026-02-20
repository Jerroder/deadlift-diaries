//
//  AppIntent.swift
//  TimerWidget
//
//  Created by Jerroder on 2026-01-26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// App Intent for controlling the timer from Live Activity
struct ToggleTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    static var description = IntentDescription("Pause or resume the timer")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        print("ToggleTimerIntent: Setting flag")
        
        // Set flag with timestamp to trigger action when app opens
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date().timeIntervalSince1970, forKey: "pendingToggleTimestamp")
        userDefaults.synchronize()
        
        return .result()
    }
}

struct ResetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description = IntentDescription("Reset the timer to the beginning")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        print("ResetTimerIntent: Setting flag")
        
        // Set flag with timestamp to trigger action when app opens
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date().timeIntervalSince1970, forKey: "pendingResetTimestamp")
        userDefaults.synchronize()
        
        return .result()
    }
}
