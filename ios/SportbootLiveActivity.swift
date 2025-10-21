//
//  SportbootLiveActivity.swift
//  SportbootLiveActivity
//
//  Live Activity widget showing daily study progress
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct SportbootLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // Lock Screen and Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text(context.attributes.courseName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label {
                            Text("\(context.state.currentStreak)")
                                .font(.title3)
                                .fontWeight(.bold)
                        } icon: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                        Text("Tage")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text("Tägliches Ziel")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Progress circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 60, height: 60)

                            Circle()
                                .trim(from: 0, to: progressPercentage(context.state))
                                .stroke(
                                    context.state.isGoalAchieved ? Color.green : Color.blue,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: context.state.questionsCompleted)

                            VStack(spacing: 0) {
                                Text("\(context.state.questionsCompleted)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("/\(context.state.targetQuestions)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if context.state.isGoalAchieved {
                            Text("🎉 Ziel erreicht!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Beantwortet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(context.state.questionsCompleted)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Fortschritt")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(progressPercentage(context.state) * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact Leading - shown on the left in Dynamic Island
                Image(systemName: context.state.isGoalAchieved ? "checkmark.circle.fill" : "book.fill")
                    .foregroundColor(context.state.isGoalAchieved ? .green : .blue)
            } compactTrailing: {
                // Compact Trailing - shown on the right in Dynamic Island
                HStack(spacing: 2) {
                    Text("\(context.state.questionsCompleted)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("/\(context.state.targetQuestions)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } minimal: {
                // Minimal presentation - shown when multiple activities are active
                Image(systemName: context.state.isGoalAchieved ? "checkmark.circle.fill" : "book.fill")
                    .foregroundColor(context.state.isGoalAchieved ? .green : .blue)
            }
        }
    }

    private func progressPercentage(_ state: LiveActivitiesAppAttributes.ContentState) -> Double {
        guard state.targetQuestions > 0 else { return 0 }
        return min(Double(state.questionsCompleted) / Double(state.targetQuestions), 1.0)
    }
}

// Lock Screen / Banner View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text(context.attributes.courseName)
                    .font(.headline)
                Spacer()
                if context.state.isGoalAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tägliches Ziel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(context.state.questionsCompleted) / \(context.state.targetQuestions)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(context.state.isGoalAchieved ? Color.green : Color.blue)
                            .frame(
                                width: geometry.size.width * progressPercentage(context.state),
                                height: 8
                            )
                            .animation(.easeInOut, value: context.state.questionsCompleted)
                    }
                }
                .frame(height: 8)
            }

            // Stats Row
            HStack(spacing: 20) {
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(context.state.currentStreak) Tage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Achievement indicator
                if context.state.isGoalAchieved {
                    Text("🎉 Ziel erreicht!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
    }

    private func progressPercentage(_ state: LiveActivitiesAppAttributes.ContentState) -> Double {
        guard state.targetQuestions > 0 else { return 0 }
        return min(Double(state.questionsCompleted) / Double(state.targetQuestions), 1.0)
    }
}

// Preview
#if DEBUG
struct LiveActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let attributes = LiveActivitiesAppAttributes(courseName: "SBF-See")
        let state = LiveActivitiesAppAttributes.ContentState(
            questionsCompleted: 7,
            targetQuestions: 10,
            currentStreak: 5,
            isGoalAchieved: false,
            lastUpdated: Date()
        )

        return LockScreenLiveActivityView(
            context: ActivityViewContext(
                state: state,
                attributes: attributes
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
