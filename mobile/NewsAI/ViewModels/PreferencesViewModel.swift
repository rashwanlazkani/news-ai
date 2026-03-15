import SwiftUI

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var selectedTopics: Set<String> = []
    @Published var selectedSubInterests: Set<String> = []
    @Published var isSaving = false
    @Published var savedSuccessfully = false
    @Published var errorMessage: String?

    private let userId: String
    private static let topicsKey = "savedTopics"
    private static let subInterestsKey = "savedSubInterests"

    init(userId: String) {
        self.userId = userId
        if let saved = UserDefaults.standard.stringArray(forKey: Self.topicsKey) {
            self.selectedTopics = Set(saved)
        }
        if let saved = UserDefaults.standard.stringArray(forKey: Self.subInterestsKey) {
            self.selectedSubInterests = Set(saved)
        }
    }

    var interestDescription: String {
        guard !selectedSubInterests.isEmpty else { return "" }
        return "Specifically interested in: " + selectedSubInterests.sorted().joined(separator: ", ")
    }

    func toggleSubInterest(_ sub: String) {
        if selectedSubInterests.contains(sub) {
            selectedSubInterests.remove(sub)
        } else {
            selectedSubInterests.insert(sub)
        }
    }

    func save() async {
        guard !selectedTopics.isEmpty else {
            errorMessage = "Pick at least one topic"
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await APIClient.shared.updatePreferences(
                userId: userId,
                topics: Array(selectedTopics),
                interestDescription: interestDescription
            )
            UserDefaults.standard.set(Array(selectedTopics), forKey: Self.topicsKey)
            UserDefaults.standard.set(Array(selectedSubInterests), forKey: Self.subInterestsKey)
            savedSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
