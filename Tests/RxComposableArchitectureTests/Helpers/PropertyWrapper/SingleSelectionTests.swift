import RxCocoa
import RxSwift
import RxTest
import XCTest

@testable import RxComposableArchitecture

internal final class SingleSelectionTests: XCTestCase {
    internal var disposeBag = DisposeBag()
    
    internal struct Item: Equatable, HashDiffable, Selectable {
        internal let id: Int
        internal var isSelected: Bool
    }
    
    internal enum ItemAction: Equatable { case tap }
    
    internal struct State: Equatable {
        @SingleSelection
        internal var items: IdentifiedArrayOf<Item> = IdentifiedArrayOf(
            [
                Item(id: 0, isSelected: false),
                Item(id: 1, isSelected: false),
                Item(id: 2, isSelected: false),
                Item(id: 3, isSelected: false),
                Item(id: 4, isSelected: false)
            ]
        )
    }
    
    internal enum Action: Equatable { case item(id: Int, action: ItemAction) }
    
    internal func testSingleSelection() {
        let itemReducer = Reducer<State, Action, Void> { state, action, _ in
            switch action {
            case let .item(id, action: .tap):
                state.items[id: id]!.isSelected = true
            }
            return .none
        }
        let store = TestStore(initialState: State(), reducer: itemReducer, environment: ())
        
        store.assert(
            .send(.item(id: 1, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = true
                $0.items[id: 2]!.isSelected = false
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = false
            },
            .send(.item(id: 2, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = false
                $0.items[id: 2]!.isSelected = true
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = false
            },
            .send(.item(id: 4, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = false
                $0.items[id: 2]!.isSelected = false
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = true
            }
        )
    }
    
    internal func testSingleSelectionFromParent() {
        let itemReducer = Reducer<Item, ItemAction, Void> { state, action, _ in
            switch action {
            case .tap:
                state.isSelected = true
            }
            return .none
        }
        let reducer = itemReducer.forEach(
            state: \State.items,
            action: /Action.item,
            environment: { $0 }
        )
        let store = TestStore(initialState: State(), reducer: reducer, environment: ())
        
        store.assert(
            .send(.item(id: 1, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = true
                $0.items[id: 2]!.isSelected = false
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = false
            },
            .send(.item(id: 2, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = false
                $0.items[id: 2]!.isSelected = true
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = false
            },
            .send(.item(id: 4, action: .tap)) {
                $0.items[id: 0]!.isSelected = false
                $0.items[id: 1]!.isSelected = false
                $0.items[id: 2]!.isSelected = false
                $0.items[id: 3]!.isSelected = false
                $0.items[id: 4]!.isSelected = true
            }
        )
    }
}
