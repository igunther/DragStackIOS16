import SwiftUI

struct ListContainer<Content: View>: View {
    let type: ListType
    let editMode: ListEditMode

    @ViewBuilder var content: Content
    
    init(
        type: ListType,
        editMode: ListEditMode,
        @ViewBuilder content: () -> Content
    ) {
        self.type = type
        self.editMode = editMode
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.listType, type)
            .environment(\.listEditMode, editMode)
    }
}
