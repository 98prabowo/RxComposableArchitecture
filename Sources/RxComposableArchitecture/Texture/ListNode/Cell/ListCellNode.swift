import TextureSwiftSupport

open class ListCellNode: ASCellNode {
    internal var diffableValue: AnyHashDiffable?
    
    public internal(set) weak var containerNode: ASCollectionNode?
    
    open func didSelectItem(at index: Int) {}
    
    internal func didUpdate(from oldValue: AnyHashDiffable?, to newValue: AnyHashDiffable) {
        diffableValue = newValue
        if oldValue != nil {
            valueUpdated(to: newValue)
        }
    }

    open func valueUpdated(to item: AnyHashDiffable) {}

    internal func valueUpdated(to item: Any) {}
}

// MARK: - Switchable Cells

open class ListUpdatableCellNode<T>: ListCellNode {
    open override func valueUpdated(to item: AnyHashDiffable) {
        guard let newValue = item.base as? T else {
            assertionFailure("Unable to transform to \(T.self)")
            return
        }
        didUpdate(newValue: newValue)
    }
    
    internal override func valueUpdated(to item: Any) {
        if let item = item as? AnyHashDiffable {
            valueUpdated(to: item)
        } else if let newValue = item as? T {
            didUpdate(newValue: newValue)
        } else {
            assertionFailure("Can't convert to \(T.self)")
        }
    }
    
    open func didUpdate(newValue: T) {
        assertionFailure("Please override didUpdate method to make the cell update its data")
    }
}

public class SwitchCaseListCellNode<Root>: ListCellNode {
    public struct Matcher {
        private let root: Root
        private let setNode: (ListCellNode) -> Void
        
        internal var extract: ((Root) -> Any?)?
        
        internal init(
            root: Root,
            setNode: @escaping (ListCellNode) -> Void
        ) {
            self.root = root
            self.setNode = setNode
        }
        
        public mutating func addMatch<Value>(
            value: @escaping (Root) -> Value?,
            createNode: (Value) -> ListUpdatableCellNode<Value>
        ) {
            guard let extractedValue = value(root) else { return }
            setNode(createNode(extractedValue))
            extract = value
        }
    }
    
    private var matcher: Matcher?
    private var baseNode: ListCellNode?
    
    public init(root: Root, matches: (inout Matcher) -> Void) {
        super.init()
        
        automaticallyManagesSubnodes = true
        clipsToBounds = false
        
        var matcher = Matcher(root: root) { [weak self] baseNode in
            guard let self else { return }
            self.baseNode = baseNode
        }
        
        matches(&matcher)
        
        self.matcher = matcher
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        guard let baseNode else {
            return ASLayoutSpec().styled { style in
                style.preferredSize = CGSize(width: 0.001, height: 0.001)
            }
        }
        
        return ASWrapperLayoutSpec(layoutElement: baseNode)
    }
    
    public override func valueUpdated(to item: AnyHashDiffable) {
        guard let newValue = item.base as? Root,
              let matcher,
              let extractedNewValue = matcher.extract?(newValue) else { return }
        valueUpdated(to: extractedNewValue)
    }
}

// MARK: - Helper Cells

public class EmptyListCellNode: ListCellNode {
    public override init() {
        super.init()
        style.preferredSize = CGSize(width: 0.001, height: 0.001)
    }
}

public class LoadMoreIndicatorListCellNode: ListCellNode {
    private let activityIndicatorNode: ViewWrapperNode<UIActivityIndicatorView> = ViewWrapperNode(createView: {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    })
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        style.width = ASDimensionMake("100%")
        
        activityIndicatorNode.style.preferredSize = CGSize(width: 32, height: 32)
    }
    
    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASWrapperLayoutSpec(layoutElement: activityIndicatorNode)
    }

    override public func didEnterVisibleState() {
        super.didEnterVisibleState()
        (activityIndicatorNode.view as? UIActivityIndicatorView)?.startAnimating()
    }
}
