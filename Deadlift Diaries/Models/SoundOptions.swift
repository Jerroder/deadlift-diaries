//
//  SoundOptions.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import Foundation

enum SoundOptions {
    static let all: [(id: UInt32, name: String)] = [
        (0, "no_sound".localized(comment: "No sound")),
        (1023, "choo_choo".localized(comment: "Choo Choo")),
        (1052, "beep".localized(comment: "Beep")),
        (1057, "tink".localized(comment: "Tink")),
        (1070, "busy".localized(comment: "Busy")),
        (1071, "congestion".localized(comment: "Congestion")),
        (1075, "key_tone".localized(comment: "Key Tone")),
        (1103, "tink_2".localized(comment: "Tink 2")),
        (1110, "begin".localized(comment: "Begin")),
        (1111, "confirm".localized(comment: "Confirm")),
        (1114, "end_record".localized(comment: "End Record")),
        (1255, "short_double_high".localized(comment: "Short Double High")),
        (1257, "short_double_low".localized(comment: "Short Double Low")),
        (1328, "news_flash".localized(comment: "News Flash"))
    ]
}
