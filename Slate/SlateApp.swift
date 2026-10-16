import SlateComposition
import SwiftUI

@main
struct SlateApp: App {
    @NSApplicationDelegateAdaptor(AppContainer.self) private var container

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
