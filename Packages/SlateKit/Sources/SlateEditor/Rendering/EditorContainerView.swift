import AppKit

final class EditorContainerView: NSView {
    let scrollView: NSScrollView
    let bar = PasteAsCodeBar()
    private var barHeight: NSLayoutConstraint?

    init(scrollView: NSScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
        bar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar)
        addSubview(scrollView)
        let height = bar.heightAnchor.constraint(equalToConstant: 0)
        barHeight = height
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.topAnchor.constraint(equalTo: topAnchor),
            height,
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        bar.isHidden = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setBarVisible(_ visible: Bool) {
        bar.isHidden = visible == false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            barHeight?.constant = visible ? 30 : 0
            layoutSubtreeIfNeeded()
        }
    }
}
