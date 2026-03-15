import SwiftUI

@main
struct NewsAIApp: App {
    // Replace with a real auth system (Sign in with Apple, etc.) later.
    // For now a stable device-scoped ID is used so preferences persist across launches.
    @AppStorage("userId") private var userId: String = UUID().uuidString

    var body: some Scene {
        WindowGroup {
            RootView(userId: userId)
        }
    }
}
