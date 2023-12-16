import RxCocoa
import RxSwift
import TextureSwiftSupport

/// An` ASCollectionNode` that will automatically be updated on state change.
public final class ListStoreNode<State, Action>: ASCollectionNode
where State: Collection,
      State: Equatable,
      State.Element: HashDiffable,
      State.Element: Equatable,
      Action: Equatable {
    private let store: Store<State, (State.Element.IdentifierType, Action)>
    private let id: KeyPath<State.Element, State.Element.IdentifierType>
    private let content: (Store<State.Element, Action>) -> ASDisplayNode
    
    private let disposeBag = DisposeBag()
    
    internal private(set) var items: [State.Element] = []
    internal private(set) var cellNodes: [ListStoreCellNode] = []
    
    private lazy var proxy = ListStoreNodeProxy(listStoreNode: self)
    
    /// Whether batch update should be animated. Default to `false`.
    public var shouldAnimateUpdate: Bool = false
    
    /// Schedules a block to be performed (on main thread) by the completion block of performBatchUpdates:.
    public var onDidCompleteUpdate: (Bool) -> Void = { _ in }
    
    public override var dataSource: ASCollectionDataSource? {
        didSet {
            if oldValue != nil {
                assertionFailure("The data source is already defined")
            }
        }
    }
    
    /**
     Init `ListStoreNode`
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - id: keypath to HashDiffable identifier.
        - collectionViewLayout: layout information of the collection view.
        - content: set what node to use on `ListStoreNode`.
     
     ## Example where ChildState is Struct
     
     ```
     struct AppState {
        var childs: [ChildState]
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, id: \.id, collectionViewLayout: UICollectionViewFlowLayout()) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ListStoreNode`
        ...
        ...
        childNode.backgroundColor = .white
     
        return childNode
     }
     ```
     
     ## Example where ChildState is Enum
     
     ```
     struct AppState {
        var childs: [ChildState]
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, id: \.id, collectionViewLayout: UICollectionViewFlowLayout()) { elementStore in
        SwitchCaseStoreNode(store: elementStore) { matcher in
            matcher.addMatch(
                state: /ChildState.caseA,
                action: ChildAction.caseA,
                createNode: { caseAStore in
                    CaseANode(store: caseAStore)
                }
            )
     
            matcher.addMatch(
                state: /ChildState.caseB,
                action: ChildAction.caseB,
                createNode: { caseBStore in
                    CaseBNode(store: caseBStore)
                }
            )
        }
     }
     ```
     */
    public init(
        store: Store<State, (State.Element.IdentifierType, Action)>,
        id: KeyPath<State.Element, State.Element.IdentifierType>,
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.store = store
        self.id = id
        self.content = content
        super.init(
            frame: .zero,
            collectionViewLayout: collectionViewLayout,
            layoutFacilitator: nil
        )
        
        dataSource = proxy
        style.flexGrow = 1
    }
    
    /**
     Init `ListStoreNode` with Never as childs action
     
     Recommended to use `IdentifiedArray`, as the performance accessing random index on the collection is much better compare to plain array.
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `Never` as action.
        - id: keypath to `HashDiffable` identifier
        - collectionViewLayout: layout information of the collection view.
        - content: set what node to use on `ListStoreNode`.
     
     ## Example
     
     ```
     struct AppState {
        var childs: [ChildState] or IdentifiedArrayOf<ChildState>
     }
     
     let store = store.scope(state: \AppState.childs).actionless
     
     let node = ListStoreNode(store: store) {
         let childNode = ChildNode(with: store)
     
         // setup neccessary thing here, before node being passed to `ListStoreNode`
         ...
         ...
         childNode.backgroundColor = .baseWhite
         return childNode
     }
     ```
     */
    public convenience init(
        store: Store<State, Never>,
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) where Action == Never {
        func noAction<A>(id: State.Element.IdentifierType, action: Never) -> A {}
        
        self.init(
            store: store.scope(
                state: { $0 },
                action: noAction
            ),
            id: \.id,
            collectionViewLayout: collectionViewLayout,
            content: content
        )
    }
    
    /**
     Init `ListStoreNode`
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - id: keypath to HashDiffable identifier.
        - collectionViewLayout: layout information of the collection view.
        - content: set what node to use on `ListStoreNode`.
     
     ## Example where ChildState is Struct
     
     ```
     struct AppState {
        var childs: IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, id: \.id, collectionViewLayout: UICollectionViewFlowLayout()) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ListStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     
     ## Example where ChildState is Enum
     
     ```
     struct AppState {
        var childs: IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, id: \.id, collectionViewLayout: UICollectionViewFlowLayout()) { elementStore in
        SwitchCaseStoreNode(store: elementStore) { matcher in
            matcher.addMatch(
                state: /ChildState.caseA,
                action: ChildAction.caseA,
                createNode: { caseAStore in
                    CaseANode(store: caseAStore)
                }
            )
     
            matcher.addMatch(
                state: /ChildState.caseB,
                action: ChildAction.caseB,
                createNode: { caseBStore in
                    CaseBNode(store: caseBStore)
                }
            )
        }
     }
     ```
     */
    public convenience init(
        store: Store<IdentifiedArrayOf<State.Element>, (State.Element.IdentifierType, Action)>,
        id: KeyPath<State.Element, State.Element.IdentifierType>,
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.init(
            store: store.scope(
                state: { $0.elements as! State }
            ),
            id: id,
            collectionViewLayout: collectionViewLayout,
            content: content
        )
    }
    
    /**
     Init `ListStoreNode`
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - collectionViewLayout: layout information of the collection view.
        - content: set what node to use on `ListStoreNode`.
     
     ## Example where ChildState is Struct
     
     ```
     struct AppState {
        var childs: [ChildState]
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, collectionViewLayout: UICollectionViewFlowLayout()) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ListStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     
     ## Example where ChildState is Enum
     
     ```
     struct AppState {
        var childs: [ChildState]
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, collectionViewLayout: UICollectionViewFlowLayout()) { elementStore in
        SwitchCaseStoreNode(store: elementStore) { matcher in
            matcher.addMatch(
                state: /ChildState.caseA,
                action: ChildAction.caseA,
                createNode: { caseAStore in
                    CaseANode(store: caseAStore)
                }
            )
     
            matcher.addMatch(
                state: /ChildState.caseB,
                action: ChildAction.caseB,
                createNode: { caseBStore in
                    CaseBNode(store: caseBStore)
                }
            )
        }
     }
     ```
     */
    public convenience init(
        store: Store<State, (State.Element.IdentifierType, Action)>,
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.init(
            store: store,
            id: \.id,
            collectionViewLayout: collectionViewLayout,
            content: content
        )
    }
    
    /**
     Init `ListStoreNode`
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - id: keypath to HashDiffable identifier.
        - collectionViewLayout: layout information of the collection view.
        - content: set what node to use on `ListStoreNode`.
     
     ## Example where ChildState is Struct
     
     ```
     struct AppState {
        var childs: IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, collectionViewLayout: UICollectionViewFlowLayout()) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ListStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     
     ## Example where ChildState is Enum
     
     ```
     struct AppState {
        var childs: IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ListStoreNode(store: store, collectionViewLayout: UICollectionViewFlowLayout()) { elementStore in
        SwitchCaseStoreNode(store: elementStore) { matcher in
            matcher.addMatch(
                state: /ChildState.caseA,
                action: ChildAction.caseA,
                createNode: { caseAStore in
                    CaseANode(store: caseAStore)
                }
            )
     
            matcher.addMatch(
                state: /ChildState.caseB,
                action: ChildAction.caseB,
                createNode: { caseBStore in
                    CaseBNode(store: caseBStore)
                }
            )
        }
     }
     ```
     */
    public convenience init(
        store: Store<IdentifiedArrayOf<State.Element>, (State.Element.IdentifierType, Action)>,
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.init(
            store: store,
            id: \.id,
            collectionViewLayout: collectionViewLayout,
            content: content
        )
    }
    
    public override func didLoad() {
        super.didLoad()
        
        // Set Identifier to ASCollectionView for Monitoring
        view.accessibilityIdentifier = "ListStoreNode-\(closestViewController?.description ?? "")"
        
        store.observable
            .throttle(.milliseconds(100), scheduler: MainScheduler.instance)
            .distinctUntilChanged { lhs, rhs -> Bool in
                guard lhs.count == rhs.count else { return false }
                return zip(lhs, rhs).allSatisfy { $0.id == $1.id }
            }
            .asDriver { _ in .empty() }
            .drive(onNext: { [weak self] newItems in
                guard let self = self else { return }
                
                if let newItems = newItems as? [State.Element] {
                    self.performUpdates(newItems: newItems)
                } else if let newItems = newItems as? IdentifiedArrayOf<State.Element> {
                    self.performUpdates(newItems: newItems.elements)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func performUpdates(newItems: [State.Element]) {
        assertMainThread("performUpdates")
        
        let oldItemsForDiffing: [AnyHashDiffable] = items.map(AnyHashDiffable.init)
        let newItemsForDiffing: [AnyHashDiffable] = newItems.map(AnyHashDiffable.init).removeDuplicates()
        
        let listDiff: DiffingInterfaceList.Result = DiffingInterfaceList.diffing(
            oldArray: oldItemsForDiffing,
            newArray: newItemsForDiffing
        )
        
        items = newItemsForDiffing.compactMap { $0.base as? State.Element }
        cellNodes = diffingCellNode(newItems: newItemsForDiffing, diff: listDiff)
        
        let deletes: IndexSet = listDiff.deletes
        let inserts: IndexSet = listDiff.inserts
        let moves: [DiffingInterfaceList.MoveIndex] = listDiff.moves
        
        performBatch(
            animated: shouldAnimateUpdate,
            updates: {
                deleteSections(deletes)
                insertSections(inserts)
                moves.forEach { moveSection($0.from, toSection: $0.to) }
            },
            completion: onDidCompleteUpdate
        )
    }
    
    private func diffingCellNode(newItems: [AnyHashDiffable], diff: DiffingInterfaceList.Result) -> [ListStoreCellNode] {
        /* The Order of updating collection must followed the rule like this:
           - Create a mutable copy A1
           - Do all reloads (But we do not do it here, because Store will handle that)
           - Delete from array A1 in descending order
           - Perform inserts in ascending order
           - Move from array A into A1
         https://github.com/Instagram/IGListKit/issues/1006#issuecomment-342579413
         */
        
        var copyCellNodes = cellNodes
        
        diff.deletes.sorted(by: >).forEach { index in
            copyCellNodes.remove(at: index)
        }
        
        diff.inserts.sorted(by: <).forEach { index in
            guard
                newItems.indices.contains(index),
                let stateElement = newItems[index].base as? State.Element,
                let elementStore = store.scope(
                    at: stateElement[keyPath: id],
                    action: { [id] action in
                        (stateElement[keyPath: id], action)
                    }
                )
            else { return }
            
            let cellNode = createCellNode(store: elementStore)
            copyCellNodes.insert(cellNode, at: index)
        }
        
        // ListDiff moves return a pair items intead a single item thus we can't use swap operation
        // in order to achieve the moves, we need to delete `from` index and insert object in `to` index
        let fromMoves = diff.moves.map(\.to).sorted(by: >)
        fromMoves.forEach { index in
            if copyCellNodes.count > index {
                copyCellNodes.remove(at: index)
            } else {
                assertItemIndexNotFound("diffingListCellNodes-move-delete", index)
            }
        }
        
        diff.moves.forEach { move in
            if cellNodes.indices.contains(move.from) {
                if copyCellNodes.count + 1 > move.to {
                    copyCellNodes.insert(cellNodes[move.from], at: move.to)
                } else {
                    assertItemIndexNotFound("diffingListCellNodes-move-insert-item", move.to)
                }
            } else {
                assertItemIndexNotFound("diffingListCellNodes-move-insert-safeindex", move.from)
            }
        }
        
        return copyCellNodes
    }
    
    private func createCellNode(store: Store<State.Element, Action>) -> ListStoreCellNode {
        let node = content(store)
        return ListStoreCellNode(rootNode: node)
    }
    
    public override func reloadData() {
        assertMainThread("reloadData")
        
        cellNodes = items
            .compactMap { [id] item -> Store<State.Element, Action>? in
                store.scope(
                    at: item[keyPath: id],
                    action: { [id] action in
                        (item[keyPath: id], action)
                    }
                )
            }
            .map(createCellNode)
        
        super.reloadData()
        view.collectionViewLayout.invalidateLayout()
    }
    
    /**
     Getter current view based on respective id
     
     - Parameters:
        - id: element `IdentifierType`
     - Returns: A Node
     */
    public func subnode(id: State.Element.IdentifierType) -> ASDisplayNode? {
        guard
            let index = items.firstIndex(where: { $0.id == id })
        else { return nil }
        
        return cellNodes[safe: index]?.rootNode
    }
}

/// Proxy for ListStoreNode that stores data source and delegates
private class ListStoreNodeProxy<State, Action>: NSObject, ASCollectionDataSource
where State: Collection,
      State: Equatable,
      State.Element: Equatable,
      State.Element: HashDiffable,
      Action: Equatable {
    private weak var listStoreNode: ListStoreNode<State, Action>?
    
    fileprivate init(listStoreNode: ListStoreNode<State, Action>) {
        self.listStoreNode = listStoreNode
        super.init()
    }
    
    // MARK: Collection Data Sources
    
    fileprivate func numberOfSections(in _: ASCollectionNode) -> Int {
        guard let listStoreNode = listStoreNode else { return 0 }
        return listStoreNode.cellNodes.count
    }
    
    fileprivate func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
        return 1
    }
    
    fileprivate func collectionNode(_: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        listStoreNode?.cellNodes[safe: indexPath.section] ?? .emptyCell
    }
}
