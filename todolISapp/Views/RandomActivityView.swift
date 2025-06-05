//
//  RandomActivityView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct RandomActivityView: View {
    @StateObject private var viewModel = RandomActivityViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                // MARK: - Header Section
                headerSection
                
                // MARK: - Compact Slot Machines Grid
                slotMachinesSection
                
                Spacer()
                
                // MARK: - Action Buttons
                actionButtonsSection
                
            }
            .padding(.horizontal, 20)
            .navigationTitle("Random Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    historyButton
                }
            }
            .sheet(isPresented: $viewModel.showHistory) {
                historyView
            }
        }
    }
}

// MARK: - View Components
extension RandomActivityView {
    
    // Simplified header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Random Activity Generator")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Tap each category to randomize")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // Vertical layout for slot machines - full width
    private var slotMachinesSection: some View {
        VStack(spacing: 12) {
            
            CompactSlotView(
                category: .whereToGo,
                result: viewModel.whereToGoResult,
                isRolling: viewModel.whereToGoRolling
            ) {
                viewModel.rollWhereToGo()
            }
            
            CompactSlotView(
                category: .whatToDo,
                result: viewModel.whatToDoResult,
                isRolling: viewModel.whatToDoRolling
            ) {
                viewModel.rollWhatToDo()
            }
            
            CompactSlotView(
                category: .whatToEat,
                result: viewModel.whatToEatResult,
                isRolling: viewModel.whatToEatRolling
            ) {
                viewModel.rollWhatToEat()
            }
        }
        .padding(.horizontal, 4)
    }
    
    // Simplified action buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            
            // Roll all button - more minimal design
            Button(action: {
                viewModel.rollAllSlots()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                        .font(.body)
                    
                    Text("Randomize All")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .disabled(viewModel.isAnySlotRolling)
            .opacity(viewModel.isAnySlotRolling ? 0.6 : 1.0)
            
            // Reset button
            if viewModel.hasAnyResult {
                Button(action: {
                    viewModel.resetAllSlots()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Reset")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Completion indicator
            if viewModel.allSlotsComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All activities selected")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
                .transition(.opacity)
            }
        }
    }
    
    // Minimal history button
    private var historyButton: some View {
        Button(action: {
            viewModel.toggleHistory()
        }) {
            Image(systemName: "clock")
                .foregroundColor(.accentColor)
        }
    }
    
    // History sheet view
    private var historyView: some View {
        NavigationView {
            List {
                if viewModel.hasHistory {
                    ForEach(Array(viewModel.activityHistory.enumerated()), id: \.offset) { index, activity in
                        HistoryRowView(activity: activity, index: index + 1)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No history yet")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.showHistory = false
                    }
                }
                
                if viewModel.hasHistory {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            viewModel.clearHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Compact Slot Machine Component
struct CompactSlotView: View {
    let category: ActivityCategory
    let result: ActivityOption?
    let isRolling: Bool
    let onRoll: () -> Void
    
    @State private var currentSpinIndex = 0
    @State private var spinTimer: Timer?
    @State private var allEmojis: [String] = []
    
    private var categoryColor: Color {
        switch category {
        case .whereToGo: return .blue
        case .whatToDo: return .green
        case .whatToEat: return .orange
        }
    }
    
    private var allOptions: [ActivityOption] {
        switch category {
        case .whereToGo: return ActivityData.whereToGoOptions
        case .whatToDo: return ActivityData.whatToDoOptions
        case .whatToEat: return ActivityData.whatToEatOptions
        }
    }
    
    var body: some View {
        Button(action: {
            if !isRolling {
                onRoll()
            }
        }) {
            // Unified horizontal layout for all states
            HStack(spacing: 12) {
                
                // Left: Emoji display (compact slot or result)
                if let result = result, !isRolling {
                    // Completed state - show result emoji
                    Text(result.emoji)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(10)
                } else {
                    // Empty/Rolling state - show slot display with same size as result
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Content
                        if isRolling {
                            // Spinning state
                            Text(allEmojis.isEmpty ? "🎲" : allEmojis[currentSpinIndex])
                                .font(.title2)
                                .foregroundColor(.white)
                                .blur(radius: 0.5)
                        } else {
                            // Empty state
                            Image(systemName: "hand.tap")
                                .font(.title3)
                                .foregroundColor(categoryColor.opacity(0.6))
                        }
                    }
                }
                
                // Center: Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if let result = result, !isRolling {
                        Text(result.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    } else if isRolling {
                        Text("Randomizing...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                    } else {
                        Text("Tap to randomize")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right: Status indicator
                if !isRolling && result != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else if isRolling {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(categoryColor)
                } else {
                    Image(systemName: "hand.tap")
                        .font(.title3)
                        .foregroundColor(categoryColor.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isRolling ? categoryColor : Color.clear,
                                lineWidth: isRolling ? 2 : 0
                            )
                            .animation(.easeInOut(duration: 0.3), value: isRolling)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            setupEmojis()
        }
        .onChange(of: isRolling) { _, newValue in
            if newValue {
                startSpinning()
            } else {
                stopSpinning()
            }
        }
    }
    
    private func setupEmojis() {
        allEmojis = allOptions.map { $0.emoji }
        let extraSymbols = ["🎲", "⚡", "✨", "🔄"]
        allEmojis.append(contentsOf: extraSymbols)
        allEmojis.shuffle()
    }
    
    private func startSpinning() {
        currentSpinIndex = 0
        
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.08)) {
                currentSpinIndex = (currentSpinIndex + 1) % allEmojis.count
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            spinTimer?.invalidate()
            
            spinTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentSpinIndex = (currentSpinIndex + 1) % allEmojis.count
                }
            }
        }
    }
    
    private func stopSpinning() {
        spinTimer?.invalidate()
        spinTimer = nil
    }
}

// MARK: - Simplified History Row
struct HistoryRowView: View {
    let activity: RandomActivity
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(index)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(formatDate(activity.generatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 6) {
                ActivityTag(title: activity.whereToGo.title, color: .blue)
                ActivityTag(title: activity.whatToDo.title, color: .green)
                ActivityTag(title: activity.whatToEat.title, color: .orange)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Activity Tag Component
struct ActivityTag: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Preview
#Preview {
    RandomActivityView()
}