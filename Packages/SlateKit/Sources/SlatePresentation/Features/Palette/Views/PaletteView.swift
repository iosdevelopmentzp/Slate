import SwiftUI
import SlateDomain
import SlateUI

struct PaletteView: View {
    @Environment(PaletteStore.self) private var palette
    @Environment(NoteListStore.self) private var noteList
    @Environment(EditorStore.self) private var editor
    @Environment(VaultStore.self) private var vault
    @Environment(SearchStore.self) private var search
    @Environment(DailyStore.self) private var daily
    @Environment(HistoryStore.self) private var history
    @Environment(SettingsStore.self) private var settings
    @Environment(Navigator.self) private var navigator
    @Environment(Toaster.self) private var toaster
    @Environment(\.openAsWindow) private var openAsWindow
    @Environment(\.openSettings) private var openSettings
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var palette = palette
        let items = palette.items(commands: commands)
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Find a note or a command", text: $palette.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isFocused)
                    .onSubmit { run(items, inWindow: false) }
                    .onKeyPress(.downArrow) {
                        palette.move(1, count: items.count)
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        palette.move(-1, count: items.count)
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        palette.close()
                        return .handled
                    }
                    .onKeyPress(keys: [.return], phases: .down) { press in
                        guard press.modifiers.contains(.command) else { return .ignored }
                        run(items, inWindow: true)
                        return .handled
                    }
                    .onKeyPress(keys: ["c"], phases: .down) { press in
                        guard press.modifiers.contains(.command), case .note(let hit)? = items[safe: palette.selection] else { return .ignored }
                        toaster.copy(settings.vaultPath + "/" + hit.summary.path.rawValue, label: "Path")
                        return .handled
                    }
            }
            .padding(12)
            if items.isEmpty == false {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { position, item in
                                if position == 0 || group(of: items[position - 1]) != group(of: item) {
                                    Text(groupTitle(item).uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 14)
                                        .padding(.top, 8)
                                        .padding(.bottom, 2)
                                }
                                row(item, isSelected: position == palette.selection)
                                    .id(item.id)
                                    .onTapGesture {
                                        palette.selection = position
                                        run(items, inWindow: false)
                                    }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 360)
                    .onChange(of: palette.selection) { _, value in
                        guard items.indices.contains(value) else { return }
                        proxy.scrollTo(items[value].id)
                    }
                }
            }
        }
        .frame(width: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))
        .onAppear { isFocused = true }
    }

    private func row(_ item: PaletteItem, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            switch item {
            case .note(let hit):
                Image(systemName: vault.type(named: hit.summary.type)?.icon ?? "note.text")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(SearchResultMapper.highlighted(hit.summary.title, words: palette.words))
                        .lineLimit(1)
                    if hit.snippet.isEmpty == false {
                        Text(SearchResultMapper.highlighted(hit.snippet, words: palette.words))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let space = hit.summary.space {
                    Text(space.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .command(let command):
                Image(systemName: command.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(command.title)
                    .lineLimit(1)
                Spacer()
                if let keys = command.keys {
                    Text(keys)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isSelected ? Theme.selection.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }

    private func group(of item: PaletteItem) -> Int {
        switch item {
        case .note: palette.query.trimmingCharacters(in: .whitespaces).isEmpty ? 2 : 0
        case .command: 1
        }
    }

    private func groupTitle(_ item: PaletteItem) -> String {
        switch group(of: item) {
        case 0: "Notes"
        case 1: "Commands"
        default: "Recent"
        }
    }

    private func run(_ items: [PaletteItem], inWindow: Bool) {
        guard let item = items[safe: palette.selection] ?? items.first else { return }
        palette.close()
        switch item {
        case .note(let hit):
            if inWindow { openAsWindow() }
            if navigator.source != .all, hit.summary.space.map({ navigator.source != .space($0) }) ?? true {
                navigator.show(.all)
            }
            navigator.select(hit.id)
            if palette.words.isEmpty == false {
                search.revealMatch(hit.id, words: palette.words)
            }
        case .command(let command):
            command.run()
        }
    }

    private var commands: [PaletteCommand] {
        var list: [PaletteCommand] = [
            PaletteCommand("New note", icon: "square.and.pencil", keys: "⌘N") { Task { await noteList.createNote() } },
            PaletteCommand("New task", icon: "checkmark.circle", keys: "⌘⇧T") { Task { await noteList.createNote(type: NoteType.task.name) } },
            PaletteCommand("New snippet", icon: "chevron.left.forwardslash.chevron.right") { Task { await noteList.createNote(type: NoteType.snippet.name) } },
            PaletteCommand("New meeting", icon: "person.2") { Task { await noteList.createNote(type: NoteType.meeting.name) } },
            PaletteCommand("Today", icon: "calendar", keys: "⌥⌘T") { Task { await daily.openToday() } },
            PaletteCommand("Open TODOs", icon: "checklist") { noteList.show(.todos) },
            PaletteCommand("All notes", icon: "tray.full") { noteList.show(.all) },
            PaletteCommand("Trash", icon: "trash") { noteList.show(.trash) },
        ]
        for space in vault.spaces {
            list.append(PaletteCommand("Go to \(space.folder.rawValue)", icon: space.icon ?? "folder", id: "space:\(space.folder.rawValue)") { noteList.show(.space(space.folder)) })
        }
        for view in vault.views {
            list.append(PaletteCommand(view.title, icon: view.icon, id: "view:\(view.id)") { search.showSaved(view) })
        }
        if let document = editor.document {
            if document.type == NoteType.task.name {
                list.append(PaletteCommand("Mark as done", icon: "checkmark.seal", keys: "⌘⇧D") { Task { await editor.markDone() } })
            }
            for name in vault.templateNames {
                list.append(PaletteCommand("Insert template: \(vault.type(named: name)?.title ?? name.capitalized)", icon: "doc.on.doc", id: "template:\(name)") { Task { await editor.insertTemplate(named: name) } })
            }
            for action in vault.actions where action.applies(to: document) {
                list.append(PaletteCommand(action.title, icon: action.icon ?? "play", id: "action:\(action.id)") { Task { await editor.run(action) } })
            }
            list.append(PaletteCommand("Copy as Markdown", icon: "doc.on.doc") { editor.copyMarkdown() })
            list.append(PaletteCommand("Copy for Slack", icon: "bubble.left") { editor.copySlack() })
            list.append(PaletteCommand("Save as HTML", icon: "globe") { Task { await editor.saveHTML() } })
            list.append(PaletteCommand("Save as PDF", icon: "doc.richtext") { Task { await editor.savePDF() } })
        }
        if let selected = noteList.selected {
            for space in vault.spaces where space.folder != selected.space {
                list.append(PaletteCommand("Move to \(space.folder.rawValue)", icon: "folder", id: "move:\(space.folder.rawValue)") {
                    Task { await noteList.moveNote(selected, to: space.folder) }
                })
            }
            list.append(PaletteCommand(selected.pinned ? "Unpin" : "Pin", icon: "pin", keys: "⌘⇧P") { Task { await noteList.togglePin(selected) } })
            list.append(PaletteCommand("Move to Trash", icon: "trash", keys: "⌘⌫") { noteList.requestTrash(selected.id) })
        }
        list.append(PaletteCommand("Save a version now", icon: "clock.arrow.circlepath") { Task { await history.snapshotNow() } })
        list.append(PaletteCommand("Rebuild search", icon: "arrow.clockwise") { Task { await settings.rebuildIndex() } })
        list.append(PaletteCommand("Open as window", icon: "macwindow", keys: "⌘⇧O") { openAsWindow() })
        list.append(PaletteCommand("Settings", icon: "gearshape", keys: "⌘,") { openSettings() })
        return list
    }
}

#Preview("Light") {
    PaletteView()
        .previewEnvironment()
        .padding(40)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PaletteView()
        .previewEnvironment()
        .padding(40)
        .preferredColorScheme(.dark)
}
