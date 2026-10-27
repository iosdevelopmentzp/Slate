import Foundation
import Testing
@testable import SlateDomain

@Suite struct FolderMovePolicyTests {
    private let clients = FolderPath(rawValue: "Work/Clients")

    @Test func aFolderGoesUnderTheNewParent() {
        #expect(FolderMovePolicy.target(of: clients, into: FolderPath(rawValue: "Notes")) == FolderPath(rawValue: "Notes/Clients"))
    }

    @Test func aSubFolderGoesToTheTopLevel() {
        #expect(FolderMovePolicy.target(of: clients, into: nil) == FolderPath(rawValue: "Clients"))
    }

    @Test func aTopLevelFolderGoesUnderAnotherFolder() {
        #expect(FolderMovePolicy.target(of: FolderPath(rawValue: "Work"), into: FolderPath(rawValue: "Notes/2026")) == FolderPath(rawValue: "Notes/2026/Work"))
    }

    @Test func aMoveThatChangesNothingOrGoesInsideItselfIsRefused() {
        #expect(FolderMovePolicy.target(of: clients, into: clients) == nil)
        #expect(FolderMovePolicy.target(of: clients, into: FolderPath(rawValue: "Work")) == nil)
        #expect(FolderMovePolicy.target(of: clients, into: FolderPath(rawValue: "Work/Clients/2026")) == nil)
        #expect(FolderMovePolicy.target(of: FolderPath(rawValue: "Work"), into: nil) == nil)
    }
}
