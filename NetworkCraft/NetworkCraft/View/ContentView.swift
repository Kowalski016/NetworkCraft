import SwiftUI
import SwiftData

// MARK: - Точка входа в приложение
@main
struct NetworkDesignerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Node.self, Channel.self, ChannelType.self, LoadMatrix.self, ShortestPath.self])
        }
    }
}
