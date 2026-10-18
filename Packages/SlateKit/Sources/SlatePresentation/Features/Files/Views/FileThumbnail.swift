import AppKit
import QuickLookThumbnailing
import SwiftUI
import SlateUI

struct FileThumbnail: View {
    static let side: CGFloat = 32

    let url: URL
    let isImage: Bool

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: isImage ? .fill : .fit)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: Self.side, height: Self.side)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityHidden(true)
        .task(id: url) {
            guard isImage else { return }
            let scale = NSScreen.main?.backingScaleFactor ?? 2
            let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: Self.side, height: Self.side), scale: scale, representationTypes: .thumbnail)
            image = try? await QLThumbnailGenerator().generateBestRepresentation(for: request).nsImage
        }
    }
}

#Preview("Light") {
    FileThumbnail(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"), isImage: false)
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileThumbnail(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"), isImage: false)
        .padding()
        .preferredColorScheme(.dark)
}
