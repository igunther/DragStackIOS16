import SwiftUI

struct TodoScreen: View {
    @StateObject private var viewModel: ViewModel
    
    /// Edit sheet state
    @State private var itemToEdit: Item?
    /// Callback to update items in the container
    @State private var updateItemCallback: ((Item, Item) -> Void)?
    
    init?() {
        guard let viewModel = ViewModel() else {
            return nil
        }
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            ScrollView {
                ItemsView()
            }
        }
        .sheet(item: $itemToEdit) { item in
            TodoItemEditSheet(item: item) { updatedItem in
                updateItemCallback?(
                    item,
                    updatedItem
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .refreshable(action: {
            try? await Task.sleep(for: .seconds(2))
            // noting atm
        })
        .padding()
        .background(Color.brown.opacity(0.4))
    }
    
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("My Items")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
    }
    
    func ItemsView() -> some View {
        ListEditModeContainer(  
            items: viewModel.items,
            actions: .all, 
            onItemEdit: { item, updateCallback in
                itemToEdit = item
                updateItemCallback = updateCallback
            },
            onItemsChanged: { updatedItems in
                viewModel.saveItems(updatedItems)
            }
        ) { item, _ in
            ItemRow(item: item)
        } dragPreviewContent: { item in
            AnyView(
                ItemRow(
                    item: item,
                    isEditing: true
                )
                .shadow(color: Color.gray.opacity(0.4), radius: 8, x: 4, y: 4)
                .opacity(0.95)
            )
        } accessibilityLabel: { item in
            "\(item.emoji) \(item.title)"
        } accessibilityHint: { item in
            "Todo item. Double tap to edit, or use the rotor to access move and delete actions."
        }
    }
    
    private func ItemRow(
        item: Item,
        isEditing: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Button {
                    print("Test button, should not be tappable when not editing")
                } label: {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Text(isEditing ? "Edit mode active" : "Tap and hold to reorder")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .disabled(isEditing)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        )
    }
}
