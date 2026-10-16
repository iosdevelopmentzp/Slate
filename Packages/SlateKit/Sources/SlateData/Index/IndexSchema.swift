import Foundation
import GRDB

enum IndexSchema {
    static let version = 1

    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "meta") { table in
                table.column("key", .text).primaryKey()
                table.column("value", .text).notNull()
            }
        }
        return migrator
    }
}
