import SlateComposition
import SwiftUI

@main
struct SlateApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
