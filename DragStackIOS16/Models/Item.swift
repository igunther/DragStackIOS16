import Foundation

public struct Item: Identifiable, Hashable {
    public var id: UUID = .init()
    var title: String
    var emoji: String
}
