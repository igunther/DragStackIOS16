import SwiftUI
import Combine

extension TodoScreen {
    @MainActor
    final class ViewModel: ObservableObject {
        
        @Published var items: [Item] = []
        
        init?() {
            fetchItems()
        }
        
        func fetchItems() {
            items = [
                .init(title: "Edit Video", emoji: "🎬"),
                .init(title: "Wash Car", emoji: "🚗"),
                .init(title: "Clean the house", emoji: "🏠"),
                .init(title: "Tidy the garage", emoji: "🔧")
            ]
        }
        
        func saveItems(_ newItems: [Item]) {
            if items != newItems {
                print("Saving")
                items = newItems
            }
        }
        
    }
}
