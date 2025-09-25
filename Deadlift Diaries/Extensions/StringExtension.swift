//
//  StringExtensions.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-08.
//

import SwiftUI

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
