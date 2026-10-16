import Foundation
import GRDB

enum IndexSchema {
    static let version = 1

    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
                CREATE TABLE notes (
                  id TEXT PRIMARY KEY,
                  path TEXT NOT NULL UNIQUE,
                  space TEXT NOT NULL,
                  stem TEXT NOT NULL,
                  title TEXT NOT NULL,
                  type TEXT NOT NULL,
                  status TEXT, ticket TEXT, branch TEXT, mr TEXT,
                  pinned INTEGER NOT NULL DEFAULT 0,
                  created REAL NOT NULL, updated REAL NOT NULL,
                  mtime REAL NOT NULL, size INTEGER NOT NULL, hash TEXT NOT NULL,
                  preview TEXT NOT NULL,
                  open_todos INTEGER NOT NULL DEFAULT 0,
                  attachment_count INTEGER NOT NULL DEFAULT 0,
                  has_code INTEGER NOT NULL DEFAULT 0,
                  has_image INTEGER NOT NULL DEFAULT 0,
                  has_link INTEGER NOT NULL DEFAULT 0,
                  header_opaque INTEGER NOT NULL DEFAULT 0,
                  in_cloud INTEGER NOT NULL DEFAULT 0,
                  in_conflict INTEGER NOT NULL DEFAULT 0
                );
                CREATE INDEX notes_space_updated ON notes(space, updated DESC);
                CREATE INDEX notes_stem ON notes(stem COLLATE NOCASE);
                CREATE INDEX notes_ticket ON notes(ticket);
                CREATE TABLE tags (note_id TEXT NOT NULL, tag TEXT NOT NULL, PRIMARY KEY (note_id, tag));
                CREATE TABLE links (from_id TEXT NOT NULL, target TEXT NOT NULL, kind TEXT NOT NULL);
                CREATE INDEX links_target ON links(target COLLATE NOCASE);
                CREATE TABLE todos (note_id TEXT NOT NULL, line INTEGER NOT NULL, text TEXT NOT NULL, done INTEGER NOT NULL, due TEXT);
                CREATE TABLE attachments (note_id TEXT NOT NULL, file TEXT NOT NULL);
                CREATE VIRTUAL TABLE notes_fts USING fts5(
                  note_id UNINDEXED, title, body, tags, ticket,
                  tokenize = "unicode61 remove_diacritics 2 tokenchars '_-'"
                );
                """)
            try db.execute(sql: "INSERT INTO notes_fts (notes_fts, rank) VALUES ('rank', 'bm25(0.0, 10.0, 1.0, 4.0, 8.0)')")
            try db.execute(sql: "INSERT INTO meta (key, value) VALUES ('schema_version', ?)", arguments: [String(version)])
        }
        return migrator
    }
}
