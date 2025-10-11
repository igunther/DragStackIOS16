import SwiftUI

public enum ListEditMode {
    case disabled
    case enabled
    case editing
    
    public var isEditing: Bool {
        self == .editing
    }
    
    public var supportsEditing: Bool {
        self != .disabled
    }
}
