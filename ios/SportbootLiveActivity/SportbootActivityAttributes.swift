//
//  SportbootActivityAttributes.swift
//  SportbootLiveActivity
//
//  Defines the data structure for Live Activity updates
//

import Foundation
import ActivityKit

/// Attributes for the Sportboot study session Live Activity
/// These attributes remain constant throughout the Live Activity's lifetime
struct SportbootActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that changes during the Live Activity
        var questionsCompleted: Int
        var targetQuestions: Int
        var currentStreak: Int
        var isGoalAchieved: Bool
        var lastUpdated: Date
    }

    // Static data that doesn't change
    var courseName: String
}
