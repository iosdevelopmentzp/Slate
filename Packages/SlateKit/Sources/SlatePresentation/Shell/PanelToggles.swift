import SwiftUI
import SlateUI

struct PanelToggles: View {
    @Environment(WindowLayout.self) private var layout

    var body: some View {
        HStack(spacing: 4) {
            if layout.showsSidebar == false, layout.showsList == false {
                IconButton(systemImage: "sidebar.left", help: "Show the folders (⌘0)") { layout.showsSidebar = true }
                    .accessibilityLabel("Show the folders")
            }
            IconButton(systemImage: "list.bullet.rectangle", help: hint) {
                layout.showsList.toggle()
            }
            .accessibilityLabel(layout.showsList ? "Hide the notes list" : "Show the notes list")
        }
        .padding(.top, 4)
        .padding(.leading, layout.showsSidebar || layout.showsList ? 10 : WindowLayout.trafficLightsWidth)
    }

    private var hint: String {
        layout.showsList ? "Hide the notes list (⌥⌘0)" : "Show the notes list (⌥⌘0)"
    }
}

#Preview("Light") {
    PanelToggles()
        .previewEnvironment()
        .frame(width: 200, height: 40, alignment: .topLeading)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PanelToggles()
        .previewEnvironment()
        .frame(width: 200, height: 40, alignment: .topLeading)
        .preferredColorScheme(.dark)
}
