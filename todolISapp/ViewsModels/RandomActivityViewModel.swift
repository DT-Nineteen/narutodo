//
//  RandomActivityViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation
import SwiftUI

// MARK: - Random Activity ViewModel
class RandomActivityViewModel: ObservableObject {
    
    // MARK: - Published Properties for Individual Slots
    @Published var whereToGoResult: ActivityOption?
    @Published var whatToDoResult: ActivityOption?
    @Published var whatToEatResult: ActivityOption?
    
    // Individual rolling states
    @Published var whereToGoRolling: Bool = false
    @Published var whatToDoRolling: Bool = false
    @Published var whatToEatRolling: Bool = false
    
    // History and UI states
    @Published var showHistory: Bool = false
    @Published var activityHistory: [RandomActivity] = []
    
    // MARK: - Private Properties
    private let maxHistoryCount = 10 // History limit
    private let rollingDuration: Double = 2.0 // Rolling animation duration
    
    // MARK: - Initialization - Dattebayo!
    init() {
        print("🍥 RandomActivityViewModel initialized for Casino Mode")
    }
    
    // MARK: - Individual Slot Rolling Methods
    
    /// Roll the "Where to Go" slot machine
    func rollWhereToGo() {
        print("🎰 Rolling Where to Go slot...")
        whereToGoRolling = true
        
        // Add rolling delay for casino effect
        DispatchQueue.main.asyncAfter(deadline: .now() + rollingDuration) {
            self.whereToGoResult = self.getRandomOption(from: ActivityData.whereToGoOptions)
            self.whereToGoRolling = false
            self.checkAndSaveToHistory()
            print("📍 Where to Go result: \(self.whereToGoResult?.title ?? "nil")")
        }
    }
    
    /// Roll the "What to Do" slot machine
    func rollWhatToDo() {
        print("🎰 Rolling What to Do slot...")
        whatToDoRolling = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + rollingDuration) {
            self.whatToDoResult = self.getRandomOption(from: ActivityData.whatToDoOptions)
            self.whatToDoRolling = false
            self.checkAndSaveToHistory()
            print("🎮 What to Do result: \(self.whatToDoResult?.title ?? "nil")")
        }
    }
    
    /// Roll the "What to Eat" slot machine
    func rollWhatToEat() {
        print("🎰 Rolling What to Eat slot...")
        whatToEatRolling = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + rollingDuration) {
            self.whatToEatResult = self.getRandomOption(from: ActivityData.whatToEatOptions)
            self.whatToEatRolling = false
            self.checkAndSaveToHistory()
            print("🍜 What to Eat result: \(self.whatToEatResult?.title ?? "nil")")
        }
    }
    
    /// Roll all slots at once (for convenience)
    func rollAllSlots() {
        rollWhereToGo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.rollWhatToDo()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.rollWhatToEat()
        }
    }
    
    /// Reset specific slot
    func resetSlot(category: ActivityCategory) {
        switch category {
        case .whereToGo:
            whereToGoResult = nil
            print("🔄 Reset Where to Go slot")
        case .whatToDo:
            whatToDoResult = nil
            print("🔄 Reset What to Do slot")
        case .whatToEat:
            whatToEatResult = nil
            print("🔄 Reset What to Eat slot")
        }
    }
    
    /// Reset all slots
    func resetAllSlots() {
        whereToGoResult = nil
        whatToDoResult = nil
        whatToEatResult = nil
        print("🔄 Reset all slots")
    }
    
    /// Toggle history view
    func toggleHistory() {
        showHistory.toggle()
        print("📚 History view: \(showHistory ? "shown" : "hidden")")
    }
    
    /// Clear all history
    func clearHistory() {
        activityHistory.removeAll()
        print("🗑️ Activity history cleared")
    }
    
    // MARK: - Private Methods
    
    /// Get random option from array
    private func getRandomOption(from options: [ActivityOption]) -> ActivityOption {
        return options.randomElement() ?? options.first!
    }
    
    /// Check if all slots have results and save to history
    private func checkAndSaveToHistory() {
        if let whereToGo = whereToGoResult,
           let whatToDo = whatToDoResult,
           let whatToEat = whatToEatResult {
            
            let completedActivity = RandomActivity(
                whereToGo: whereToGo,
                whatToDo: whatToDo,
                whatToEat: whatToEat
            )
            
            addToHistory(completedActivity)
        }
    }
    
    /// Add activity to history
    private func addToHistory(_ activity: RandomActivity) {
        activityHistory.insert(activity, at: 0)
        
        // Limit history count
        if activityHistory.count > maxHistoryCount {
            activityHistory.removeLast()
        }
        
        print("📝 Added to history. Total: \(activityHistory.count)")
    }
    
    /// Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - State Extensions
extension RandomActivityViewModel {
    
    /// Check if any slot is currently rolling
    var isAnySlotRolling: Bool {
        whereToGoRolling || whatToDoRolling || whatToEatRolling
    }
    
    /// Check if all slots have results
    var allSlotsComplete: Bool {
        whereToGoResult != nil && whatToDoResult != nil && whatToEatResult != nil
    }
    
    /// Check if any slot has result
    var hasAnyResult: Bool {
        whereToGoResult != nil || whatToDoResult != nil || whatToEatResult != nil
    }
    
    /// Check if has history
    var hasHistory: Bool {
        !activityHistory.isEmpty
    }
    
    /// Get formatted current time
    var currentTimeString: String {
        formatDate(Date())
    }
    
    /// Get result for specific category
    func getResult(for category: ActivityCategory) -> ActivityOption? {
        switch category {
        case .whereToGo: return whereToGoResult
        case .whatToDo: return whatToDoResult
        case .whatToEat: return whatToEatResult
        }
    }
    
    /// Check if specific slot is rolling
    func isRolling(category: ActivityCategory) -> Bool {
        switch category {
        case .whereToGo: return whereToGoRolling
        case .whatToDo: return whatToDoRolling
        case .whatToEat: return whatToEatRolling
        }
    }
} 