import SwiftUI
import SlateUI

struct SettingsView: View {
    @State private var page: SettingsPage = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $page) { page in
                Label(page.title, systemImage: page.icon)
                    .tag(page)
            }
            .navigationSplitViewColumnWidth(170)
        } detail: {
            switch page {
            case .general: GeneralSettingsView()
            case .shortcuts: ShortcutSettingsView()
            }
        }
        .frame(minWidth: 640, minHeight: 440)
    }
}

#Preview("Light") {
    SettingsView()
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .previewEnvironment()
        .preferredColorScheme(.dark)
}
