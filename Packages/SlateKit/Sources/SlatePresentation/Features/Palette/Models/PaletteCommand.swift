import Foundation

struct PaletteCommand: Identifiable {
    let id: String
    let title: String
    let icon: String
    let keys: String?
    let run: () -> Void

    init(_ title: String, icon: String, keys: String? = nil, id: String? = nil, run: @escaping () -> Void) {
        self.id = id ?? title
        self.title = title
        self.icon = icon
        self.keys = keys
        self.run = run
    }
}
