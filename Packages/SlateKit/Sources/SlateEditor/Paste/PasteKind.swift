import Foundation

enum PasteKind: Equatable {
    case image(Data, fileExtension: String)
    case files([URL])
    case url(String)
    case text(String, codeLanguage: String?)
    case nothing
}
