import Foundation

struct FolderIcon: Hashable {
    let symbol: String
    let title: String

    static let all = [
        FolderIcon(symbol: "folder.fill", title: "Folder"),
        FolderIcon(symbol: "star.fill", title: "Star"),
        FolderIcon(symbol: "heart.fill", title: "Heart"),
        FolderIcon(symbol: "lightbulb.fill", title: "Idea"),
        FolderIcon(symbol: "book.fill", title: "Book"),
        FolderIcon(symbol: "briefcase.fill", title: "Work"),
        FolderIcon(symbol: "house.fill", title: "Home"),
        FolderIcon(symbol: "cart.fill", title: "Shopping"),
        FolderIcon(symbol: "airplane", title: "Travel"),
        FolderIcon(symbol: "graduationcap.fill", title: "School"),
        FolderIcon(symbol: "leaf.fill", title: "Nature"),
        FolderIcon(symbol: "music.note", title: "Music"),
        FolderIcon(symbol: "camera.fill", title: "Photos"),
        FolderIcon(symbol: "gift.fill", title: "Gifts"),
        FolderIcon(symbol: "hammer.fill", title: "Tools"),
        FolderIcon(symbol: "person.2.fill", title: "People"),
    ]
}
