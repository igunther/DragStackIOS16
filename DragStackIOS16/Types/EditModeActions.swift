import SwiftUI

public struct EditModeActions: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let delete = EditModeActions(rawValue: 1 << 0)
    public static let edit   = EditModeActions(rawValue: 1 << 1)
    public static let drag   = EditModeActions(rawValue: 1 << 2)

    public static let all: EditModeActions = [.delete, .edit, .drag]
    
    public var hasAnyActions: Bool {
        !isEmpty
    }
}
