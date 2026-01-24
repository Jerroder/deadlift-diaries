//
//  ExerciseTemplate.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-01-24.
//

import Foundation
import SwiftData

@Model
final class ExerciseTemplate: Codable {
    var id: UUID = UUID()
    
    var name: String = ""
    var defaultWeight: Double?
    var defaultSets: Int = 5
    var defaultReps: Int?
    var defaultDuration: Double?
    var defaultRestTime: Double = 30.0
    var isTimeBased: Bool = false
    var isDistanceBased: Bool = false
    var defaultDistance: Int?
    var timeBeforeNext: Double = 120.0
    var supersetPartnerTemplateID: UUID?
    var isTheSupersetTemplate: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \Exercise.template) var exercises: [Exercise]?
    @Relationship(deleteRule: .cascade) var history: [ExerciseHistory]?
    
    init(name: String, defaultWeight: Double? = nil, defaultSets: Int = 5, defaultReps: Int? = nil, defaultDuration: Double? = 30.0, defaultRestTime: Double = 30.0, isTimeBased: Bool = false, isDistanceBased: Bool = false, defaultDistance: Int? = nil, timeBeforeNext: Double = 120.0, supersetPartnerTemplateID: UUID? = nil, isTheSupersetTemplate: Bool = false) {
        self.id = UUID()
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultDuration = defaultDuration
        self.defaultRestTime = defaultRestTime
        self.isTimeBased = isTimeBased
        self.isDistanceBased = isDistanceBased
        self.defaultDistance = defaultDistance
        self.timeBeforeNext = timeBeforeNext
        self.supersetPartnerTemplateID = supersetPartnerTemplateID
        self.isTheSupersetTemplate = isTheSupersetTemplate
    }
    
    enum CodingKeys: CodingKey {
        case id, name, defaultWeight, defaultSets, defaultReps, defaultDuration, defaultRestTime, isTimeBased, isDistanceBased, defaultDistance, timeBeforeNext, supersetPartnerTemplateID, isTheSupersetTemplate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(defaultWeight, forKey: .defaultWeight)
        try container.encode(defaultSets, forKey: .defaultSets)
        try container.encode(defaultReps, forKey: .defaultReps)
        try container.encode(defaultDuration, forKey: .defaultDuration)
        try container.encode(defaultRestTime, forKey: .defaultRestTime)
        try container.encode(isTimeBased, forKey: .isTimeBased)
        try container.encode(isDistanceBased, forKey: .isDistanceBased)
        try container.encode(defaultDistance, forKey: .defaultDistance)
        try container.encode(timeBeforeNext, forKey: .timeBeforeNext)
        try container.encode(supersetPartnerTemplateID, forKey: .supersetPartnerTemplateID)
        try container.encode(isTheSupersetTemplate, forKey: .isTheSupersetTemplate)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.defaultWeight = try container.decodeIfPresent(Double.self, forKey: .defaultWeight)
        self.defaultSets = try container.decode(Int.self, forKey: .defaultSets)
        self.defaultReps = try container.decodeIfPresent(Int.self, forKey: .defaultReps)
        self.defaultDuration = try container.decodeIfPresent(Double.self, forKey: .defaultDuration)
        self.defaultRestTime = try container.decode(Double.self, forKey: .defaultRestTime)
        self.isTimeBased = try container.decode(Bool.self, forKey: .isTimeBased)
        self.isDistanceBased = try container.decode(Bool.self, forKey: .isDistanceBased)
        self.defaultDistance = try container.decodeIfPresent(Int.self, forKey: .defaultDistance)
        self.timeBeforeNext = try container.decode(Double.self, forKey: .timeBeforeNext)
        self.supersetPartnerTemplateID = try container.decodeIfPresent(UUID.self, forKey: .supersetPartnerTemplateID)
        self.isTheSupersetTemplate = try container.decodeIfPresent(Bool.self, forKey: .isTheSupersetTemplate) ?? false
    }
}

extension ExerciseTemplate: Identifiable {}
