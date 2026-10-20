import Foundation
import GRDB
import SlateDomain

struct GRDBSearchIndex: SearchIndex {
    let writer: any DatabaseWriter

    static let tagSeparator = "\u{1F}"
    static let summaryColumns = """
        n.id, n.path, n.title, n.type, n.status, n.ticket, n.pinned, n.created, n.updated, n.preview,
        n.open_todos, n.attachment_count, n.header_opaque,
        (SELECT group_concat(tag, char(31)) FROM tags t WHERE t.note_id = n.id) AS tag_list
        """

    init(writer: any DatabaseWriter) throws {
        self.writer = writer
        try IndexSchema.migrator().migrate(writer)
    }

    static func open(at url: URL, vaultPath: String) throws -> GRDBSearchIndex {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let existing = try? openPool(url), (try? isCurrent(existing, vaultPath: vaultPath)) == true {
            return try GRDBSearchIndex(writer: existing)
        }
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + suffix)
        }
        let pool = try openPool(url)
        let index = try GRDBSearchIndex(writer: pool)
        try pool.write { db in
            try db.execute(sql: "INSERT OR REPLACE INTO meta (key, value) VALUES ('vault_path', ?)", arguments: [vaultPath])
        }
        return index
    }

    private static func openPool(_ url: URL) throws -> DatabasePool {
        var configuration = Configuration()
        configuration.busyMode = .timeout(2)
        return try DatabasePool(path: url.path, configuration: configuration)
    }

    private static func isCurrent(_ pool: DatabasePool, vaultPath: String) throws -> Bool {
        try pool.read { db in
            guard try db.tableExists("meta") else { return false }
            let version = try String.fetchOne(db, sql: "SELECT value FROM meta WHERE key = 'schema_version'")
            let path = try String.fetchOne(db, sql: "SELECT value FROM meta WHERE key = 'vault_path'")
            return version == String(IndexSchema.version) && path == vaultPath
        }
    }

    func summaries(space: SpaceName?) async throws -> [NoteSummary] {
        try await writer.read { db in
            if let space {
                return try Row.fetchAll(db, sql: "SELECT \(Self.summaryColumns) FROM notes n WHERE n.space = ? ORDER BY n.updated DESC", arguments: [space.rawValue]).map(Self.summary)
            }
            return try Row.fetchAll(db, sql: "SELECT \(Self.summaryColumns) FROM notes n ORDER BY n.updated DESC").map(Self.summary)
        }
    }

    func summary(id: NoteID) async throws -> NoteSummary? {
        try await writer.read { db in
            try Row.fetchOne(db, sql: "SELECT \(Self.summaryColumns) FROM notes n WHERE n.id = ?", arguments: [id.rawValue]).map(Self.summary)
        }
    }

    func fileStates() async throws -> [VaultPath: IndexedFileState] {
        try await writer.read { db in
            var states: [VaultPath: IndexedFileState] = [:]
            for row in try Row.fetchAll(db, sql: "SELECT path, mtime, size, hash FROM notes") {
                let path = VaultPath(rawValue: row["path"])
                states[path] = IndexedFileState(modified: Date(timeIntervalSince1970: row["mtime"]), size: row["size"], hash: ContentHash(rawValue: row["hash"]))
            }
            return states
        }
    }

    func upsert(_ note: IndexedNote) async throws {
        try await upsert(contentsOf: [note])
    }

    func upsert(contentsOf notes: [IndexedNote]) async throws {
        guard notes.isEmpty == false else { return }
        try await writer.write { db in
            for note in notes {
                try Self.write(note, in: db)
            }
        }
    }

    func updateState(_ state: IndexedFileState, for path: VaultPath) async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE notes SET mtime = ?, size = ?, hash = ? WHERE path = ?", arguments: [state.modified.timeIntervalSince1970, state.size, state.hash.rawValue, path.rawValue])
        }
    }

    func remove(path: VaultPath) async throws {
        try await writer.write { db in
            try Self.delete(where: "path = ?", [path.rawValue], in: db)
        }
    }

    func search(_ query: SearchQuery, limit: Int) async throws -> [SearchHit] {
        let match = FTSMatchBuilder.match(terms: query.terms, phrases: query.phrases)
        let filters = SearchSQL(query: query)
        let hits: [SearchHit] = try await writer.read { db in
            if match.isEmpty {
                let sql = "SELECT \(Self.summaryColumns) FROM notes n WHERE \(filters.whereClause) ORDER BY n.pinned DESC, n.updated DESC LIMIT ?"
                let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(filters.arguments + [limit.databaseValue]))
                return rows.map { row in
                    let summary = Self.summary(row)
                    return SearchHit(summary: summary, excerpt: summary.preview, rank: 0)
                }
            }
            let sql = """
                SELECT \(Self.summaryColumns), notes_fts.rank AS rank, snippet(notes_fts, 2, '', '', '…', 12) AS snippet
                FROM notes_fts JOIN notes n ON n.rowid = notes_fts.rowid
                WHERE notes_fts MATCH ? AND \(filters.whereClause)
                ORDER BY notes_fts.rank LIMIT ?
                """
            let arguments: [DatabaseValue] = [match.databaseValue] + filters.arguments + [max(limit * 2, 100).databaseValue]
            return try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments)).map { row in
                SearchHit(summary: Self.summary(row), excerpt: row["snippet"] ?? "", rank: row["rank"] ?? 0)
            }
        }
        return Array(SearchMatchPolicy.sorted(hits, words: query.words).prefix(limit))
    }

    func notes(named stem: String) async throws -> [NoteSummary] {
        try await writer.read { db in
            try Row.fetchAll(db, sql: "SELECT \(Self.summaryColumns) FROM notes n WHERE n.stem = ? COLLATE NOCASE ORDER BY n.updated DESC", arguments: [stem]).map(Self.summary)
        }
    }

    func notes(withTicket ticket: String) async throws -> [NoteSummary] {
        try await writer.read { db in
            try Row.fetchAll(db, sql: "SELECT \(Self.summaryColumns) FROM notes n WHERE n.ticket = ? COLLATE NOCASE ORDER BY n.updated DESC", arguments: [ticket]).map(Self.summary)
        }
    }

    func notesLinking(to stem: String) async throws -> [NoteSummary] {
        try await writer.read { db in
            let sql = """
                SELECT DISTINCT \(Self.summaryColumns) FROM links l JOIN notes n ON n.id = l.from_id
                WHERE l.kind IN ('wiki', 'note') AND (lower(l.target) = lower(?) OR lower(l.target) LIKE '%/' || lower(?))
                ORDER BY n.updated DESC
                """
            return try Row.fetchAll(db, sql: sql, arguments: [stem, stem]).map(Self.summary)
        }
    }

    func tags() async throws -> [TagCount] {
        try await writer.read { db in
            try Row.fetchAll(db, sql: "SELECT tag, COUNT(*) AS count FROM tags GROUP BY tag ORDER BY tag").map { TagCount(tag: $0["tag"], count: $0["count"]) }
        }
    }

    func todos(isDone: Bool) async throws -> [TodoItem] {
        try await writer.read { db in
            try Row.fetchAll(db, sql: "SELECT note_id, line, text, done FROM todos WHERE done = ? ORDER BY note_id, line", arguments: [isDone]).map { row in
                TodoItem(noteID: NoteID(rawValue: row["note_id"]), line: row["line"], text: row["text"], isDone: row["done"])
            }
        }
    }

    func reset() async throws {
        try await writer.write { db in
            for table in ["notes", "tags", "links", "todos", "attachments", "notes_fts"] {
                try db.execute(sql: "DELETE FROM \(table)")
            }
        }
    }

    private static func write(_ note: IndexedNote, in db: Database) throws {
        let summary = note.summary
        try delete(where: "path = ?", [summary.path.rawValue], in: db)
        var id = summary.id.rawValue
        if try String.fetchOne(db, sql: "SELECT path FROM notes WHERE id = ?", arguments: [id]) != nil {
            id = NoteID.forPath(summary.path).rawValue
            try delete(where: "id = ?", [id], in: db)
        }
        try db.execute(
            sql: """
                INSERT INTO notes (id, path, space, stem, title, type, status, ticket, pinned, created, updated, mtime, size, hash, preview,
                  open_todos, attachment_count, has_code, has_image, has_link, header_opaque)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
            arguments: [
                id, summary.path.rawValue, summary.space?.rawValue ?? "", summary.stem, summary.title, summary.type,
                summary.status?.rawValue, summary.ticket, summary.pinned, summary.created.timeIntervalSince1970, summary.updated.timeIntervalSince1970,
                note.state.modified.timeIntervalSince1970, note.state.size, note.state.hash.rawValue, summary.preview,
                summary.openTodos, summary.attachmentCount, note.hasCode, note.hasImage, note.hasLink, summary.headerOpaque,
            ]
        )
        let rowID = db.lastInsertedRowID
        for tag in summary.tags {
            try db.execute(sql: "INSERT OR IGNORE INTO tags (note_id, tag) VALUES (?, ?)", arguments: [id, tag])
        }
        for link in note.links {
            try db.execute(sql: "INSERT INTO links (from_id, target, kind) VALUES (?, ?, ?)", arguments: [id, link.target, link.kind.rawValue])
        }
        for todo in note.todos {
            try db.execute(sql: "INSERT INTO todos (note_id, line, text, done) VALUES (?, ?, ?, ?)", arguments: [id, todo.line, todo.text, todo.isDone])
        }
        for file in note.attachments {
            try db.execute(sql: "INSERT INTO attachments (note_id, file) VALUES (?, ?)", arguments: [id, file])
        }
        try db.execute(
            sql: "INSERT INTO notes_fts (rowid, note_id, title, body, tags, ticket) VALUES (?, ?, ?, ?, ?, ?)",
            arguments: [rowID, id, summary.title, note.body, summary.tags.joined(separator: " "), summary.ticket ?? ""]
        )
    }

    private static func delete(where condition: String, _ arguments: [any DatabaseValueConvertible], in db: Database) throws {
        let rows = try Row.fetchAll(db, sql: "SELECT rowid, id FROM notes WHERE \(condition)", arguments: StatementArguments(arguments))
        for row in rows {
            let rowID: Int64 = row["rowid"]
            let id: String = row["id"]
            try db.execute(sql: "DELETE FROM notes_fts WHERE rowid = ?", arguments: [rowID])
            for table in ["tags", "todos", "attachments"] {
                try db.execute(sql: "DELETE FROM \(table) WHERE note_id = ?", arguments: [id])
            }
            try db.execute(sql: "DELETE FROM links WHERE from_id = ?", arguments: [id])
            try db.execute(sql: "DELETE FROM notes WHERE rowid = ?", arguments: [rowID])
        }
    }

    private static func summary(_ row: Row) -> NoteSummary {
        let tagList: String? = row["tag_list"]
        let status: String? = row["status"]
        return NoteSummary(
            id: NoteID(rawValue: row["id"]),
            path: VaultPath(rawValue: row["path"]),
            title: row["title"],
            type: row["type"],
            status: status.flatMap(NoteStatus.init(rawValue:)),
            ticket: row["ticket"],
            pinned: row["pinned"],
            created: Date(timeIntervalSince1970: row["created"]),
            updated: Date(timeIntervalSince1970: row["updated"]),
            preview: row["preview"],
            openTodos: row["open_todos"],
            attachmentCount: row["attachment_count"],
            headerOpaque: row["header_opaque"],
            tags: tagList.map { $0.components(separatedBy: tagSeparator).sorted() } ?? []
        )
    }
}
