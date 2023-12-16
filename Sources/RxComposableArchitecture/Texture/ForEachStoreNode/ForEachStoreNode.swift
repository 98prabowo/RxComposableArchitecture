import CasePaths
import RxSwift
import TextureSwiftSupport

/// A structure that computes views on demand from a store on a collection of data.
public final class ForEachStoreNode<State, Action>: ASDisplayNode
    where State: Collection,
    State: Equatable,
    State.Element: Equatable,
    State.Element: RxComposableArchitecture.HashDiffable,
    Action: Equatable {
    // MARK: - Views
    
    internal var nodes: [ASDisplayNode] = []
    
    // MARK: - Values
    
    private let disposeBag = DisposeBag()
    private let layoutSpecOptions: LayoutSpecOptions
    
    /// Flag, is current stackNode is diffing or not
    private var isDiffing: Bool = false
    
    /// Closure to generate element node by passing data
    private let node: (Store<State.Element, Action>) -> ASDisplayNode
    
    /// Set data to current `StackNode`
    internal var currentValue: [Store<State.Element, Action>] = [] {
        didSet {
            synchronousDiffing.append {
                self.applyDiffing(
                    lhs: oldValue.map { $0.state },
                    rhs: self.currentValue.map { $0.state }
                )
            }
        }
    }
    
    /// Synchronus queue
    private var synchronousDiffing: [() -> Void] = [] {
        didSet {
            while !synchronousDiffing.isEmpty {
                guard !isDiffing else { return }
                let action = synchronousDiffing.removeFirst()
                action()
            }
        }
    }
    
    // MARK: - Life Cycle
    
    /**
     Init `ForEachStoreNode`
     
     Recommended to use `IdentifiedArray`, as the performance accessing random index on the collection is much better compare to plain array.
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - id: keypath to `HashDiffable` identifier
        - layoutSpecOptions: configure layout spec options
        - node: set how node to use on `ForEachStoreNode`. on this block of closure, you can add the neccessary configuration before used on `ForEachStoreNode`
     
     ## Example
     
     ```
     struct AppState {
        var childs: [ChildState] or IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ForEachStoreNode(store: store, id: \.id) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ForEachStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     */
    public init(
        store: Store<State, (State.Element.IdentifierType, Action)>,
        id: KeyPath<State.Element, State.Element.IdentifierType>,
        layoutSpecOptions: LayoutSpecOptions = .init(),
        node: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.layoutSpecOptions = layoutSpecOptions
        self.node = node
        
        super.init()
        
        automaticallyManagesSubnodes = true
        
        store.observable
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                guard lhs.count == rhs.count else { return false }
                return zip(lhs, rhs).allSatisfy { $0.id == $1.id }
            }
            .subscribe(onNext: { [unowned self] elementValue in
                self.currentValue = elementValue.compactMap { value -> Store<State.Element, Action>? in
                    store.scope(at: value[keyPath: id], action: { (value[keyPath: id], $0) })
                }
            })
            .disposed(by: disposeBag)
    }
    
    /**
     Init `ForEachStoreNode` with Never as childs action
     
     Recommended to use `IdentifiedArray`, as the performance accessing random index on the collection is much better compare to plain array.
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `Never` as action.
        - id: keypath to `HashDiffable` identifier
        - layoutSpecOptions: configure layout spec options
        - node: set how node to use on `ForEachStoreNode`. on this block of closure, you can add the neccessary configuration before used on `ForEachStoreNode`
     
     ## Example

     ```
     struct AppState {
        var childs: [ChildState] or IdentifiedArrayOf<ChildState>
     }
     
     let store = store.scope(state: \AppState.childs).actionless
     
     let node = ForEachStoreNode(store: store, id: \.id) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ForEachStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     */
    public init(
        store: Store<State, Never>,
        id: KeyPath<State.Element, State.Element.IdentifierType>,
        layoutSpecOptions: LayoutSpecOptions = .init(),
        node: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) where Action == Never {
        self.layoutSpecOptions = layoutSpecOptions
        self.node = node
        
        super.init()
        
        automaticallyManagesSubnodes = true
        
        store.observable
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                guard lhs.count == rhs.count else { return false }
                return zip(lhs, rhs).allSatisfy { $0.id == $1.id }
            }
            .subscribe(onNext: { [unowned self] elementValue in
                self.currentValue = elementValue.compactMap { value -> Store<State.Element, Action>? in
                    func noAction<A>(_: Never) -> A {}
                    return store.scope(at: value[keyPath: id], action: noAction)
                }
            })
            .disposed(by: disposeBag)
    }
    
    /**
     Init `ForEachStoreNode`
     
     Recommended to use `IdentifiedArray`, as the performance accessing random index on the collection is much better compare to plain array.
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `(IdentifierType, Action)` as action.
        - layoutSpecOptions: configure layout spec options
        - node: set how node to use on `ForEachStoreNode`. on this block of closure, you can add the neccessary configuration before used on `ForEachStoreNode`
     
     ## Example

     ```
     struct AppState {
        var childs: [ChildState] or IdentifiedArrayOf<ChildState>
     }
     
     enum AppAction {
        case child(identifier: String, action: ChildAction)
     }
     
     let store = store.scope(
        state: \AppState.childs,
        action: AppAction.child(identifier:action:)
     )
     
     let node = ForEachStoreNode(store: store) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ForEachStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     */
    public convenience init(
        store: Store<State, (State.Element.IdentifierType, Action)>,
        layoutSpecOptions: LayoutSpecOptions = .init(),
        node: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) {
        self.init(
            store: store,
            id: \.id,
            layoutSpecOptions: layoutSpecOptions,
            node: node
        )
    }
    
    /**
     Init `ForEachStoreNode` with Never as childs action
     
     Recommended to use `IdentifiedArray`, as the performance accessing random index on the collection is much better compare to plain array.
     
     - Parameters:
        - store: store that contains `Collection` of `ElementState` as state, and `Never` as action.
        - layoutSpecOptions: configure layout spec options
        - node: set how node to use on `ForEachStoreNode`. on this block of closure, you can add the neccessary configuration before used on `ForEachStoreNode`
     
     ## Example
     
     ```
     struct AppState {
        var childs: [ChildState] or IdentifiedArrayOf<ChildState>
     }
     
     let store = store.scope(state: \AppState.childs).actionless
     
     let node = ForEachStoreNode(store: store, id: \.id) {
        let childNode = ChildNode(with: store)
     
        // setup neccessary thing here, before node being passed to `ForEachStoreNode`
        ...
        ...
        childNode.backgroundColor = .baseWhite
     
        return childNode
     }
     ```
     */
    public convenience init(
        store: Store<State, Never>,
        layoutSpecOptions: LayoutSpecOptions = .init(),
        node: @escaping (Store<State.Element, Action>) -> ASDisplayNode
    ) where Action == Never {
        self.init(
            store: store,
            id: \.id,
            layoutSpecOptions: layoutSpecOptions,
            node: node
        )
    }
    
    // MARK: Layout
    
    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec(
            direction: layoutSpecOptions.stackDirection,
            spacing: layoutSpecOptions.spacing,
            justifyContent: layoutSpecOptions.justifyContent,
            alignItems: layoutSpecOptions.alignItems,
            children: nodes
        )
        
        stack.flexWrap = layoutSpecOptions.flexWrap
        stack.lineSpacing = layoutSpecOptions.lineSpacing
        
        let insets = ASInsetLayoutSpec(
            insets: layoutSpecOptions.insets,
            child: stack
        )
        
        return insets
    }
    
    // MARK: Private Implementations
    
    private func applyDiffing(lhs: [State.Element], rhs: [State.Element]) {
        isDiffing = true
        var refreshLayout: Bool = false
        
        defer {
            if refreshLayout {
                setNeedsLayout()
                supernode?.setNeedsLayout()
            }

            isDiffing = false
        }
        
        let changes = DiffingInterfaceList.diffing(oldArray: lhs, newArray: rhs)
        refreshLayout = changes.hasChanges
        
        /// clone before changes
        let clone = nodes
        
        /// apply delete
        changes.deletes.reversed().forEach { deleted in
            self.nodes.remove(at: deleted)
        }
        
        /// apply insert
        changes.inserts.forEach { inserted in
            let store = self.currentValue[inserted]
            let node = self.node(store)
            self.nodes.insert(node, at: inserted)
        }
        
        /// remove element on `nodes` from top `to` moves changes
        changes.moves.map(\.to).sorted(by: >).forEach { offset in
            self.nodes.remove(at: offset)
        }
        
        /// insert moves changes
        changes.moves.forEach { moved in
            // take original value that will be move
            let sourceElement = clone[moved.from]
            
            self.nodes.insert(sourceElement, at: moved.to)
        }
    }
    
    /// Getter current view based on respective id
    ///
    /// - Parameters:
    ///    - id: element `IdentifierType`
    /// - Returns: A Node
    public func subnode(id: State.Element.IdentifierType) -> ASDisplayNode? {
        if let index = currentValue.firstIndex(where: { $0.state.id == id }),
            nodes.indices.contains(index) {
            return nodes[index]
        } else {
            return nil
        }
    }
}
