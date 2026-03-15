import SwiftUI

/// Decides whether to show the topic picker (first launch) or the news feed.
struct RootView: View {
    let userId: String

    // True when the user has never saved preferences in this app install.
    @AppStorage("hasSetPreferences") private var hasSetPreferences = false
    @State private var showingTopicPicker = false

    var body: some View {
        if hasSetPreferences && !showingTopicPicker {
            NewsFeedView(userId: userId) {
                showingTopicPicker = true
            }
            .sheet(isPresented: $showingTopicPicker) {
                TopicPickerView(userId: userId) {
                    showingTopicPicker = false
                }
            }
        } else {
            TopicPickerView(userId: userId) {
                hasSetPreferences = true
                showingTopicPicker = false
            }
        }
    }
}
