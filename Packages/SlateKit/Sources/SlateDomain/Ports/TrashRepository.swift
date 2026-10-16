import Foundation

package protocol TrashRepository: Sendable {
    func trash(_ path: VaultPath, at date: Date) async throws -> TrashItem
    func restore(_ item: TrashItem) async throws -> VaultPath
    func items() async throws -> [TrashItem]
}
