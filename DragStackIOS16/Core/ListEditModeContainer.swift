import SwiftUI

private enum MoveDirection {
    case up
    case down
}

/// A reusable container that manages a list with full edit capabilities
/// Handles drag/drop, delete confirmations, and edit operations internally
/// Works with local copy and notifies parent only when changes are complete
public struct ListEditModeContainer: View {
    let initialItems: [Item]
    let actions: EditModeActions
    let onItemEdit: (Item, @escaping (Item, Item) -> Void) -> Void
    let onItemsChanged: ([Item]) -> Void
    let itemContent: (Item, Bool) -> AnyView
    let dragPreviewContent: ((Item) -> AnyView)?
    let accessibilityLabel: ((Item) -> String)?
    let accessibilityHint: ((Item) -> String)?
    
    /// Local working copy of items
    @State private var items: [Item]
    
    /// Internal edit mode state
    @State private var editMode: ListEditMode = .enabled
    
    /// Tracks which item is currently being dragged
    @State private var currentlyDragging: Item?
    
    /// Tracks which item is currently being targeted for drop
    @State private var dragTargetItem: Item?
    
    /// Delete confirmation state
    @State private var pendingDelete: Item?
    @State private var showDeleteConfirmation = false
    
    /// Track previous edit state to detect transitions
    @State private var previousEditState = false
    
    public init(
        items: [Item],
        actions: EditModeActions = .all,
        onItemEdit: @escaping (Item, @escaping (Item, Item) -> Void) -> Void,
        onItemsChanged: @escaping ([Item]) -> Void,
        @ViewBuilder itemContent: @escaping (Item, Bool) -> some View,
        dragPreviewContent: ((Item) -> AnyView)? = nil,
        accessibilityLabel: ((Item) -> String)? = nil,
        accessibilityHint: ((Item) -> String)? = nil
    ) {
        self.initialItems = items
        self.actions = actions
        self.onItemEdit = onItemEdit
        self.onItemsChanged = onItemsChanged
        self.itemContent = { item, editing in AnyView(itemContent(item, editing)) }
        self.dragPreviewContent = dragPreviewContent
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self._items = State(initialValue: items)
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            ListEditModeHeader(
                editMode: $editMode,
                actions: actions,
                onCancel: {
                    // Reset to original items
                    resetItems(initialItems)
                }
            )
            
            // List content
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items) { item in
                    ItemWrapperView(item: item)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .alert("Delete item", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let toDelete = pendingDelete {
                    deleteItem(toDelete)
                    pendingDelete = nil
                }
            }
        } message: {
            Text("Are you sure?")
        }
        .onChange(of: editMode.isEditing) { newValue in
            if previousEditState && !newValue {
                saveChanges()
                clearDragState()
            }
            previousEditState = newValue
        }
        .onChange(of: initialItems) { newItems in
            // Update local items when external items change (but only if not currently editing)
            if !editMode.isEditing {
                items = newItems
            }
        }
        .onAppear {
            previousEditState = editMode.isEditing
        }
    }
    
    private func ItemWrapperView(item: Item) -> some View {
        HStack(spacing: 12) {
            // Left: Delete button
            if editMode.isEditing && actions.contains(.delete) {
                deleteButton(for: item)
            }
            
            // Middle: Content
            itemContent(
                item,
                editMode.isEditing
            )
            
            // Right: Edit and drag controls
            if editMode.isEditing && (actions.contains(.edit) || actions.contains(.drag)) {
                editControls(for: item)
            }
        }
        // Apply drag and drop functionality
        .if(editMode.isEditing && actions.contains(.drag)) { view in
            view
                .draggable("\(item.id)") {
                    if let dragPreviewContent {
                        dragPreviewContent(item)
                            .onAppear {
                                currentlyDragging = item
                            }
                    }
                }
                .dropDestination(for: String.self) { _, _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        clearDragState()
                    }
                    return true
                } isTargeted: { status in
                    handleDropTarget(
                        item: item,
                        isTargeted: status
                    )
                }
        }
        // VoiceOver accessibility
        .accessibilityElement(children: editMode.isEditing ? .ignore : .contain)
        .if(editMode.isEditing) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: item))
                .accessibilityHint(accessibilityHint(for: item))
                .accessibilityActions {
                    // Add accessibility actions for available operations
                    if actions.contains(.delete) {
                        Button("Delete") {
                            pendingDelete = item
                            showDeleteConfirmation = true
                        }
                    }
                    
                    if actions.contains(.edit) {
                        Button("Edit") {
                            onItemEdit(item, updateItem)
                        }
                    }
                    
                    if actions.contains(.drag) {
                        Button("Move Up") {
                            moveItem(
                                item,
                                direction: .up
                            )
                        }
                        .disabled(!canMoveUp(item))
                        
                        Button("Move Down") {
                            moveItem(
                                item,
                                direction: .down
                            )
                        }
                        .disabled(!canMoveDown(item))
                    }
                }
                .accessibilityAddTraits(.isButton)
        }
    }
    
    private func deleteButton(for item: Item) -> some View {
        Button {
            pendingDelete = item
            showDeleteConfirmation = true
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.red)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Delete item")
    }
    
    private func editControls(for item: Item) -> some View {
        HStack(spacing: 8) {
            if actions.contains(.edit) {
                editButton(for: item)
            }
            
            if actions.contains(.drag) {
                dragHandle
            }
        }
    }
    
    private func editButton(for item: Item) -> some View {
        Button {
            onItemEdit(
                item,
                updateItem
            )
        } label: {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Edit item")
    }
    
    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
            )
            .accessibilityLabel("Drag to reorder")
    }
    
    /// Call this to save current changes
    public func saveChanges() {
        onItemsChanged(items)
    }
    
    private func clearDragState() {
        currentlyDragging = nil
        dragTargetItem = nil
    }
    
    private func resetItems(_ newItems: [Item]) {
        withAnimation(.easeInOut) {
            items = newItems
        }
    }
    
    public func updateItem(
        originalItem: Item,
        updatedItem: Item
    ) {
        if let index = items.firstIndex(where: { $0.id == originalItem.id }) {
            withAnimation(.easeInOut) {
                items[index] = updatedItem
            }
        }
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation(.easeInOut) {
            items.removeAll { $0.id == item.id }
        }
    }
    
    private func handleDropTarget(
        item: Item,
        isTargeted: Bool
    ) {
        guard let currentlyDragging = currentlyDragging,
              currentlyDragging.id != item.id else {
            return
        }
        
        if isTargeted {
            dragTargetItem = item
            
            withAnimation(.snappy) {
                if let sourceIndex = items.firstIndex(where: { $0.id == currentlyDragging.id }),
                   let destinationIndex = items.firstIndex(where: { $0.id == item.id }) {
                    
                    let draggedItem = items.remove(at: sourceIndex)
                    items.insert(draggedItem, at: destinationIndex)
                }
            }
        } else {
            dragTargetItem = nil
        }
    }
    
    // MARK: - Move Functionality
    
    private func moveItem(
        _ item: Item,
        direction: MoveDirection
    ) {
        guard let currentIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        let newIndex: Int
        switch direction {
        case .up:
            newIndex = currentIndex - 1
        case .down:
            newIndex = currentIndex + 1
        }
        
        guard newIndex >= 0 && newIndex < items.count else {
            return
        }
        
        withAnimation(.easeInOut) {
            let movedItem = items.remove(at: currentIndex)
            items.insert(movedItem, at: newIndex)
        }
    }
    
    private func canMoveUp(_ item: Item) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        return currentIndex > 0
    }
    
    private func canMoveDown(_ item: Item) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        return currentIndex < items.count - 1
    }
    
    // MARK: - Accessibility Helpers
    
    private func accessibilityLabel(for item: Item) -> String {
        if let accessibilityLabel {
            return accessibilityLabel(item)
        }
        return ""
    }
    
    private func accessibilityHint(for item: Item) -> String {
        if let accessibilityHint {
            return accessibilityHint(item)
        }
        return ""
    }
}
