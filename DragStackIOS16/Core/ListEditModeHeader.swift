import SwiftUI

public struct ListEditModeHeader: View {
    @Binding var editMode: ListEditMode
    let actions: EditModeActions
    let onCancel: () -> Void
    
    public init(
        editMode: Binding<ListEditMode>,
        actions: EditModeActions,
        onCancel: @escaping () -> Void = {}
    ) {
        self._editMode = editMode
        self.actions = actions
        self.onCancel = onCancel
    }
    
    public var body: some View {
        HStack {
            Spacer()
            
            if editMode.supportsEditing && actions.hasAnyActions {
                if editMode.isEditing {
                    Button("Cancel") {
                        withAnimation(.easeInOut) {
                            editMode = .enabled
                            onCancel()
                        }
                    }
                }
                
                Button(editMode.isEditing ? "Done" : "Edit") {
                    withAnimation(.easeInOut) {
                        toggleEditMode()
                    }
                }
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundColor(editMode.isEditing ? .blue : .primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func toggleEditMode() {
        switch editMode {
        case .disabled:
            break
        case .enabled:
            editMode = .editing
        case .editing:
            editMode = .enabled
        }
    }
}
