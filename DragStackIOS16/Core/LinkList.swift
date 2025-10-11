import SwiftUI

struct LinkList<Content: View>: View {
    let editMode: ListEditMode
    @ViewBuilder var content: Content
    
    init(
        editMode: ListEditMode = .disabled,
        @ViewBuilder content: () -> Content
    ) {
        self.editMode = editMode
        self.content = content()
    }
    
    var body: some View {
        ListContainer(
            type: .linkList,
            editMode: editMode,
            content: {
                content
            })
    }
}
