import AppKit
import WebKit

final class MermaidRenderer: NSObject, WKNavigationDelegate {
    static let pageSide: CGFloat = 2400
    static let notLoaded = "Slate could not load the diagram tool."
    private static let offlineRules = "[" + ["^https?://", "^wss?://", "^ftp://"].map { #"{"trigger":{"url-filter":"\#($0)"},"action":{"type":"block"}}"# }.joined(separator: ",") + "]"

    static var bundledPage: URL? {
        Bundle.module.url(forResource: "diagram", withExtension: "html", subdirectory: "Resources")
    }

    private let page: URL?
    private var webView: WKWebView?
    private var loading: Task<Bool, Never>?
    private var loaded: CheckedContinuation<Bool, Never>?

    init(page: URL? = MermaidRenderer.bundledPage) {
        self.page = page
        super.init()
    }

    func render(_ source: String, dark: Bool) async -> DiagramPicture {
        guard let webView = await prepared() else { return DiagramPicture(image: nil, size: .zero, error: Self.notLoaded) }
        let value = try? await webView.callAsyncJavaScript(
            "return await draw(source, dark)",
            arguments: ["source": source, "dark": dark],
            contentWorld: .page
        )
        switch DiagramDrawing.parse(value) {
        case .error(let message):
            return DiagramPicture(image: nil, size: .zero, error: message)
        case .size(let size):
            let configuration = WKPDFConfiguration()
            configuration.rect = CGRect(origin: .zero, size: size)
            guard let data = try? await webView.pdf(configuration: configuration), let image = Self.image(fromPDF: data, size: size) else {
                return DiagramPicture(image: nil, size: .zero, error: DiagramDrawing.unknownError)
            }
            return DiagramPicture(image: image, size: size)
        }
    }

    static func image(fromPDF data: Data, size: CGSize) -> NSImage? {
        guard let provider = CGDataProvider(data: data as CFData), let page = CGPDFDocument(provider)?.page(at: 1) else { return nil }
        let box = page.getBoxRect(.mediaBox)
        guard box.width > 0, box.height > 0 else { return nil }
        return NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.minY)
            context.scaleBy(x: rect.width / box.width, y: rect.height / box.height)
            context.translateBy(x: -box.minX, y: -box.minY)
            context.drawPDFPage(page)
            context.restoreGState()
            return true
        }
    }

    private func prepared() async -> WKWebView? {
        if loading == nil {
            loading = Task { await load() }
        }
        guard await loading?.value == true else { return nil }
        return webView
    }

    private func load() async -> Bool {
        guard let page else { return false }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        if let store = WKContentRuleListStore.default(),
           let rules = try? await store.compileContentRuleList(forIdentifier: "slate.diagram.offline", encodedContentRuleList: Self.offlineRules) {
            configuration.userContentController.add(rules)
        }
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: Self.pageSide, height: Self.pageSide), configuration: configuration)
        view.navigationDelegate = self
        view.setValue(false, forKey: "drawsBackground")
        view.underPageBackgroundColor = .clear
        webView = view
        return await withCheckedContinuation { continuation in
            loaded = continuation
            view.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
    }

    private func finishLoading(_ success: Bool) {
        loaded?.resume(returning: success)
        loaded = nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.request.url == page ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoading(true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        finishLoading(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        finishLoading(false)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        finishLoading(false)
        self.webView = nil
        loading = nil
    }
}
