import RxComposableArchitecture
import TextureSwiftSupport

internal struct AppState: Equatable {
    internal var childs: [ChildState]
}

internal struct AppStateWithIdentifiedArray: Equatable {
    internal var childs: IdentifiedArrayOf<ChildState>
}

internal enum AppAction: Equatable {
    case child(identifier: Int, action: ChildAction)
    case replaceChilds([ChildState])
}

internal let appReducer = Reducer<AppState, AppAction, Void> { state, action, _ in
    switch action {
    case let .replaceChilds(newChilds):
        state.childs = newChilds
        return .none
    default:
        return .none
    }
}

internal struct ChildState: HashDiffable, Equatable {
    internal var id: Int
    internal var count: Int
}

internal enum ChildAction: Equatable {
    case increase
}

internal let childReducer = Reducer<ChildState, ChildAction, Void> { state, action, _ in
    switch action {
    case .increase:
        state.count += 1

        return .none
    }
}

internal final class ChildNode: ASDisplayNode {
    internal let store: Store<ChildState, ChildAction>
    internal init(with store: Store<ChildState, ChildAction>) {
        self.store = store

        super.init()
    }

    internal convenience init(state: ChildState) {
        self.init(with: Store(state: state))
    }
}

extension Store where State == ChildState, Action == ChildAction {
    internal convenience init(state: ChildState) {
        self.init(initialState: state, reducer: childReducer, environment: ())
    }
}
