import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct FolderTreeMapperTests {
    private let folders = [
        FolderPath(rawValue: "Work/clients"),
        FolderPath(rawValue: "Work/Archive"),
        FolderPath(rawValue: "Work/clients/2026"),
        FolderPath(rawValue: "Home/Garden"),
    ]

    @Test func childrenAreSortedByName() {
        #expect(FolderTreeMapper.children(of: FolderPath(rawValue: "Work"), in: folders).map(\.name) == ["Archive", "clients"])
    }

    @Test func onlyExpandedFoldersShowTheirChildren() {
        let closed = FolderTreeMapper.nodes(below: SpaceName(rawValue: "Work"), folders: folders, expanded: [])
        let open = FolderTreeMapper.nodes(below: SpaceName(rawValue: "Work"), folders: folders, expanded: [FolderPath(rawValue: "Work/clients")])

        #expect(closed.map(\.id.name) == ["Archive", "clients"])
        #expect(closed.map(\.hasChildren) == [false, true])
        #expect(open.map(\.id.name) == ["Archive", "clients", "2026"])
        #expect(open.map(\.level) == [1, 1, 2])
    }
}
