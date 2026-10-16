import GRDB
import Testing
@testable import SlateData

@Suite struct IndexSchemaTests {
    @Test func migrationCreatesTheMetaTable() throws {
        let queue = try DatabaseQueue()

        try IndexSchema.migrator().migrate(queue)

        let exists = try queue.read { db in try db.tableExists("meta") }
        #expect(exists)
    }
}
