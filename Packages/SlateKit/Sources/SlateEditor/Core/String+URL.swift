import Foundation

extension String {
    var looksLikeURL: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains(" ") == false, let url = URL(string: trimmed), let scheme = url.scheme else { return false }
        return ["http", "https", "mailto", "file"].contains(scheme.lowercased())
    }
}
