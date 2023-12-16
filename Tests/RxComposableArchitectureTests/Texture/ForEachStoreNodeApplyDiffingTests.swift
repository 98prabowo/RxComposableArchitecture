import XCTest
import TextureSwiftSupport

@testable import RxComposableArchitecture
/**
 Check diffing result on ui level
 */
internal final class ApplyDiffingTests: XCTestCase {
    internal func assertChildNode(
        _ lhs: [ChildNode],
        _ rhs: [ChildNode],
        message: (ChildNode, ChildNode) -> String = { _, _ in "" },
        file: StaticString = #file,
        line: UInt = #line
    ) {
        zip(lhs, rhs).forEach { lhs, rhs in
            XCTAssertEqual(lhs.store.state.id, rhs.store.state.id, message(lhs, rhs), file: file, line: line)
        }
    }

    internal func test_applyDiffing_reversed() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let viewStore = ViewStore(store)
        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0),
            ChildState(id: 4, count: 0)
        ]

        viewStore.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_shuffle() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0),
            ChildState(id: 4, count: 0)
        ]

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_combineInsertDeleteShuffle() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0),
            ChildState(id: 4, count: 0)
        ]

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_removeAll() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [ChildState]()

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_insertFromEmpty() {
        let store = Store(
            initialState: AppState(
                childs: []
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0),
            ChildState(id: 4, count: 0)
        ]

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_insertRandom() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 0, count: 0),
            ChildState(id: 26, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 25, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 23, count: 0),
            ChildState(id: 3, count: 0),
            ChildState(id: 22, count: 0),
            ChildState(id: 4, count: 0),
            ChildState(id: 21, count: 0)
        ]

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }

    internal func test_applyDiffing_deleteRandom() {
        let store = Store(
            initialState: AppState(
                childs: [
                    ChildState(id: 0, count: 0),
                    ChildState(id: 1, count: 0),
                    ChildState(id: 2, count: 0),
                    ChildState(id: 3, count: 0),
                    ChildState(id: 4, count: 0)
                ]
            ),
            reducer: appReducer,
            environment: ()
        )

        let childStore = store.scope(state: \.childs, action: AppAction.child(identifier:action:))
        let forEachStoreNode = ForEachStoreNode(store: childStore, node: ChildNode.init)
        forEachStoreNode.didLoad()

        let newState = [
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 4, count: 0)
        ]

        store.send(.replaceChilds(newState))
        assertChildNode(forEachStoreNode.nodes as! [ChildNode], newState.map(ChildNode.init))
    }
}
