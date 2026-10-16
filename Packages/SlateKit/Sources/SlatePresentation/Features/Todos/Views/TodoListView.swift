import SwiftUI
import SlateDomain
import SlateUI

struct TodoListView: View {
    @Environment(TodoStore.self) private var todos
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var todos = todos
        let groups = todos.groups
        VStack(spacing: 0) {
            HStack {
                Picker("Group by", selection: $todos.groupsByTicket) {
                    Text("Note").tag(false)
                    Text("Ticket").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer()
                Text(CountText.count(todos.items.count, "open item"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            ListState(
                failure: nil,
                isLoading: todos.isLoading && groups.isEmpty,
                loadingTitle: "Reading checkboxes…",
                empty: groups.isEmpty && todos.isLoading == false ? ListMessage("No open checkboxes.", systemImage: "checklist", description: "Type - [ ] in a note to add one.") : nil,
                noResultsFor: nil
            ) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groups) { group in
                            ListSectionHeader(group.title, detail: group.detail) {
                                if let id = group.noteID {
                                    IconButton(systemImage: "arrow.right.circle", help: "Open the note") {
                                        navigator.select(id)
                                    }
                                    .accessibilityLabel("Open \(group.title)")
                                }
                            }
                            .padding(.horizontal, 12)
                            ForEach(group.items, id: \.self) { item in
                                TodoRow(text: item.text, onToggle: { Task { await todos.toggle(item) } }, onOpen: { todos.open(item) })
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(Theme.surface)
        .task { await todos.refresh() }
    }
}

#Preview("Light") {
    TodoListView()
        .previewEnvironment()
        .frame(width: 320, height: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TodoListView()
        .previewEnvironment()
        .frame(width: 320, height: 480)
        .preferredColorScheme(.dark)
}
