import CasePaths
import RxSwift
import XCTest
import TextureSwiftSupport

@testable import RxComposableArchitecture

internal final class ListStoreNodeWithArrayTests: XCTestCase {
    private let disposeBag = DisposeBag()
    private var actualReducerOnParent: [(Int, ChildAction)] = []

    override internal func tearDown() {
        super.tearDown()
        actualReducerOnParent.removeAll()
    }

    internal func test_items_shouldHaveNoDuplicate() {
        let childs = [
            ChildState(id: 0, count: 0),
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0)
        ]

        let (_, listStore) = setupListStore(state: AppState(childs: childs))
        listStore.didLoad()

        let expectedItems = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0)
        ]

        XCTAssertEqual(expectedItems, listStore.items)
    }

    internal func test_reducer_shouldHaveTriggered() {
        let childs = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0)
        ]

        let (_, listStore) = setupListStore(state: AppState(childs: childs))
        listStore.didLoad()
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 3) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)

        let expectedReducerOnParent = [
            (0, ChildAction.increase),
            (3, ChildAction.increase),
            (0, ChildAction.increase),
            (0, ChildAction.increase)
        ]

        assertReducer(expectedReducerOnParent, actualReducerOnParent)
    }

    internal func test_state_shouldEqual() {
        let childs = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0)
        ]

        let (parentStore, listStore) = setupListStore(state: AppState(childs: childs))
        listStore.didLoad()
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 3) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)
        (listStore.subnode(id: 0) as! ChildNode).store.send(.increase)

        let expectedStateOnParent = [
            ChildState(id: 0, count: 3),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 1)
        ]

        XCTAssertEqual(expectedStateOnParent, parentStore.state.childs)
    }

    internal func test_changesOnParent_shouldReflectOnChild() {
        var actualChanges: [Int] = []
        let childs = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0)
        ]

        let (parentStore, listStore) = setupListStore(state: AppState(childs: childs))
        listStore.didLoad()

        let store = (listStore.subnode(id: 0) as! ChildNode).store
        let viewStore = ViewStore(store)
        
        viewStore.publisher.count
            .subscribe(onNext: { counter in
                actualChanges.append(counter)
            })
            .disposed(by: disposeBag)

        parentStore.send(.child(identifier: 0, action: .increase))
        parentStore.send(.child(identifier: 0, action: .increase))

        let expectedChanges = [0, 1, 2]
        XCTAssertEqual(expectedChanges, actualChanges)
    }

    internal func test_redux_measurePerformance() {
        let childs = [
            ChildState(id: 0, count: 0),
            ChildState(id: 1, count: 0),
            ChildState(id: 2, count: 0),
            ChildState(id: 3, count: 0)
        ]

        /// 1000x send action ~= 8.459s
        /// 1000x send action ~= 7.779s
        /// 50x send action = 0.275s
        /// 50x send action = 0.148s
        measure {
            let (_, listStore) = setupListStore(state: AppState(childs: childs))
            listStore.didLoad()

            var count = 0

            while count < 50 {
                let randomIndex = Int.random(in: listStore.cellNodes.startIndex ..< listStore.cellNodes.endIndex)

                let store = (listStore.cellNodes[randomIndex].rootNode as! ChildNode).store
                let viewStore = ViewStore(store)
                
                viewStore.publisher.count
                    .subscribe(onNext: { _ in
                        // simulate listen to value
                    })
                    .disposed(by: disposeBag)

                (listStore.cellNodes[randomIndex].rootNode as! ChildNode).store.send(.increase)

                count += 1
            }
        }
    }

    private func assertReducer(
        _ lhs: [(Int, ChildAction)],
        _ rhs: [(Int, ChildAction)],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.count, rhs.count, "number of items is not same", file: file, line: line)

        zip(zip(lhs.indices, lhs), rhs).forEach { lhs, rhs in
            let (offset, (lhsIdentifier, lhsAction)) = lhs
            let (rhsIdentifier, rhsAction) = rhs

            XCTAssertEqual(
                lhsIdentifier,
                rhsIdentifier,
                "Identifier at index \(offset), is not equal.Expected \(lhsIdentifier) to equal to \(rhsIdentifier)",
                file: file,
                line: line
            )
            XCTAssertEqual(
                lhsAction,
                rhsAction,
                "Action at index \(offset), is not equal.Expected \(lhsAction) to equal to \(rhsAction)",
                file: file,
                line: line
            )
        }
    }

    private typealias ParentStore = Store<AppState, AppAction>
    private func setupListStore(state: AppState) -> (ParentStore, ListStoreNode<[ChildState], ChildAction>) {
        let counterReducer = Reducer<AppState, AppAction, Void>.combine(
            childReducer.forEach(
                state: \AppState.childs,
                action: /AppAction.child(identifier:action:),
                environment: { $0 }
            ),
            Reducer<AppState, AppAction, Void> { _, action, _ in
                switch action {
                case let .child(identifier, action):
                    self.actualReducerOnParent.append((identifier, action))
                    return .none
                default: return .none
                }
            }
        )

        let parentStore = Store(
            initialState: state,
            reducer: counterReducer,
            environment: ()
        )

        let childsState = parentStore.scope(
            state: \.childs,
            action: AppAction.child(identifier:action:)
        )

        return (
            parentStore,
            ListStoreNode(
                store: childsState,
                collectionViewLayout: UICollectionViewFlowLayout(),
                content: ChildNode.init
            )
        )
    }
}
