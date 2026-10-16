import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct EditorView: View {
    @Environment(EditorStore.self) private var editor
    @Environment(VaultStore.self) private var vault
    @Environment(SearchStore.self) private var search
    @Environment(NoteListStore.self) private var noteList
    @Environment(SettingsStore.self) private var settings
    @Environment(Toaster.self) private var toaster
    @State private var showsHistory = false
    @State private var showsOutline = false
    @Environment(IssueStore.self) private var issues
    @Environment(\.surface) private var surface
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        if let document = editor.document {
            VStack(alignment: .leading, spacing: 0) {
                if editor.hasConflict {
                    ConflictBanner(
                        onKeepMine: { Task { await editor.keepMine() } },
                        onTakeTheirs: { Task { await editor.takeTheirs() } },
                        onOpenBoth: { Task { await editor.openBoth() } }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if let recovered = editor.recovered {
                    RecoveryBanner(
                        savedAt: recovered.savedAt.relativeDescription(to: .now),
                        onRestore: { editor.restoreRecovered() },
                        onDiscard: { editor.discardRecovered() }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                header(for: document)
                Divider()
                MarkdownEditorView(
                    text: Bindable(editor).text,
                    configuration: configuration,
                    focus: editor.bodyFocus.map { EditorFocusRequest(token: $0.token, caret: $0.caret) },
                    insertion: editor.insertion.map { EditorInsertion(token: $0.token, markdown: $0.markdown) },
                    handlers: handlers
                )
            }
            .animation(.easeInOut(duration: 0.15), value: editor.hasConflict)
            .animation(.easeInOut(duration: 0.15), value: editor.recovered)
            .background(Theme.surface)
            .onChange(of: editor.titleFocusToken) {
                isTitleFocused = true
            }
            .onChange(of: isTitleFocused) { wasFocused, isFocused in
                guard wasFocused, isFocused == false else { return }
                editor.titleEditingEnded()
            }
        } else {
            ContentUnavailableView("No note selected.", systemImage: "note.text", description: Text("Pick a note in the list or press ⌘N."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.surface)
        }
    }

    private func header(for document: NoteDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                TextField(StemPolicy.untitled, text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(.title3.weight(.semibold))
                    .focused($isTitleFocused)
                    .onSubmit { editor.submitTitle() }
                    .disabled(document.isHeaderOpaque)
                    .accessibilityLabel("Title")
                IconButton(systemImage: "list.bullet.indent", help: "Outline") {
                    showsOutline.toggle()
                }
                .popover(isPresented: $showsOutline, arrowEdge: .bottom) {
                    OutlineView(items: OutlineItem.items(in: editor.text)) { item in
                        showsOutline = false
                        editor.reveal(location: item.location)
                    }
                }
                .accessibilityLabel("Outline")
                IconButton(systemImage: "clock.arrow.circlepath", help: "Versions of this note") {
                    showsHistory.toggle()
                }
                .popover(isPresented: $showsHistory, arrowEdge: .bottom) {
                    HistoryView(path: document.path)
                }
                .accessibilityLabel("Versions")
                NoteMenu(document: document)
            }
            let chips = NoteChipsMapper.noteChips(for: document, type: vault.type(named: document.type), ticketURL: document.header.ticket.flatMap(ticketURL))
            issueLine(document.header.ticket)
            let indexed = noteList.summaries.first { $0.id == document.id }?.tags ?? []
            let tags = TagPolicy.merged(header: document.header.tags, lines: []) + indexed.filter { (document.header.tags ?? []).map(TagPolicy.normalized).contains($0) == false }
            if chips.isEmpty == false || tags.isEmpty == false {
                FlowLayout(spacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        chipView(chip, document: document)
                    }
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            search.showTag(tag)
                        } label: {
                            ModelTag(model: TagModel("#\(tag)", tint: .secondary))
                        }
                        .buttonStyle(.plain)
                        .hint("Show notes with #\(tag)")
                        .accessibilityLabel("Show notes with the tag \(tag)")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .task(id: document.header.ticket) {
            guard let ticket = document.header.ticket else { return }
            await issues.load(ticket)
        }
    }

    @ViewBuilder
    private func issueLine(_ ticket: String?) -> some View {
        if let ticket, let issue = issues.details[ticket] {
            Text([issue.summary, issue.status, issue.assignee].compactMap { $0 }.filter { $0.isEmpty == false }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .textSelection(.enabled)
                .help("From the tracker")
        }
    }

    private var configuration: EditorConfiguration {
        let size = CGFloat(settings.editorFontSize)
        var configuration = EditorConfiguration(
            proseFont: .systemFont(ofSize: size),
            codeFont: .monospacedSystemFont(ofSize: size - 1, weight: .regular),
            lineHeightMultiple: 1.35
        )
        configuration.linkPatterns = vault.linkPatterns.map { EditorLinkPattern(id: $0.id, regex: $0.regex) }
        return configuration
    }

    private func ticketURL(_ ticket: String) -> String? {
        LinkPatternPolicy.url(for: "jira", match: ticket, patterns: vault.linkPatterns)
    }

    @ViewBuilder
    private func chipView(_ chip: NoteChip, document: NoteDocument) -> some View {
        switch chip.kind {
        case .ticket(let ticket):
            Button {
                if let url = ticketURL(ticket) {
                    Task { await editor.openURL(url) }
                } else {
                    toaster.copy(ticket, label: "Ticket")
                }
            } label: {
                ModelTag(model: chip.model)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open ticket \(ticket)")
        case .branch(let branch):
            Button {
                toaster.copy(branch, label: "Branch")
            } label: {
                ModelTag(model: chip.model)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy branch \(branch)")
        case .mergeRequest(let mr):
            Button {
                let url = mr.contains("://") ? mr : LinkPatternPolicy.url(for: "gitlab-mr", match: mr, patterns: vault.linkPatterns)
                if let url { Task { await editor.openURL(url) } }
            } label: {
                ModelTag(model: chip.model)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open merge request")
        case .status:
            Menu {
                ForEach(NoteStatus.allCases, id: \.self) { status in
                    Button(NoteStatusText.title(status)) { Task { await editor.setStatus(status) } }
                }
            } label: {
                ModelTag(model: chip.model)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .hint("Change the status (⌘⇧D marks it done)")
            .accessibilityLabel("Status")
        case .type, .folder, .details:
            ModelTag(model: chip.model)
        }
    }

    private var handlers: EditorHandlers {
        let editor = editor
        let noteList = noteList
        let search = search
        let patterns = vault.linkPatterns
        let toaster = toaster
        return EditorHandlers(
            didEndEditing: { editor.bodyEditingEnded() },
            resolveImage: { editor.resolveLink($0) },
            openLink: { link in
                Task {
                    switch link {
                    case .url(let target): await editor.openURL(target)
                    case .wiki(let target): await editor.openWikilink(target)
                    case .pattern(let id, let match):
                        if let url = LinkPatternPolicy.url(for: id, match: match, patterns: patterns) {
                            await editor.openURL(url)
                        }
                    }
                }
            },
            attachment: { link, action in
                switch action {
                case .quickLook: Task { await editor.attachment(link, quickLook: true) }
                case .open: Task { await editor.attachment(link, quickLook: false) }
                case .reveal: Task { await editor.reveal(link) }
                case .copyImage:
                    if let url = editor.resolveLink(link) { PasteboardWriter.writeImage(at: url) }
                }
            },
            pasteImage: { data, fileExtension in Task { await editor.pasteImage(data, fileExtension: fileExtension) } },
            pasteFiles: { urls in Task { await editor.pasteFiles(urls) } },
            pasteURL: { url in
                guard let short = LinkPatternPolicy.shortForm(for: url, patterns: patterns) else { return nil }
                toaster.show("Pasted as \(short). ⌘Z pastes the full link.")
                return short
            },
            requestScreenshot: { kind in Task { await editor.screenshot(kind == .region ? .region : .window) } },
            completions: { kind, prefix in
                switch kind {
                case .note: CompletionPolicy.noteNames(matching: prefix, in: noteList.summaries)
                case .tag: CompletionPolicy.tags(matching: prefix, in: search.tags)
                }
            }
        )
    }

    private var titleBinding: Binding<String> {
        Binding(get: { editor.titleFieldText }, set: { editor.editTitle($0) })
    }
}

#Preview("Light") {
    EditorView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    EditorView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.dark)
}
