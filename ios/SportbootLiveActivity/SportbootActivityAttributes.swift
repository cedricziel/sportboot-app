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
/// IMPORTANT: Must be named LiveActivitiesAppAttributes for the live_activities plugin
public struct LiveActivitiesAppAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that changes during the Live Activity
        public var questionsCompleted: Int
        public var targetQuestions: Int
        public var currentStreak: Int
        public var isGoalAchieved: Bool
        public var lastUpdated: Date

        public init(questionsCompleted: Int, targetQuestions: Int, currentStreak: Int, isGoalAchieved: Bool, lastUpdated: Date) {
            self.questionsCompleted = questionsCompleted
            self.targetQuestions = targetQuestions
            self.currentStreak = currentStreak
            self.isGoalAchieved = isGoalAchieved
            self.lastUpdated = lastUpdated
        }
    }

    // Static data that doesn't change
    public var courseName: String

    public init(courseName: String) {
        self.courseName = courseName
    }
}
