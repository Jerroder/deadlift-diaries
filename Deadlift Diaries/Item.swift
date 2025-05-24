//
//  Item.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
