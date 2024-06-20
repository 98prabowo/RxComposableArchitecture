import RxCocoa
import RxSwift
import TextureSwiftSupport

public typealias ItemCell<T> = (T) -> ListCellNode

internal protocol ListNodeType: NSObject {
    func getListCellNodes(at section: Int) -> ListCellNode?
}

public class ListNode<Item: HashDiffable & Equatable>: ASCollectionNode, ListNodeType {
    // MARK: Properties 📦
    
    private var inspector: ASCollectionViewLayoutInspector?
    
    private lazy var proxy: ListNodeProxy<Item> = ListNodeProxy(listNode: self)
    
    private let content: ItemCell<Item>
    private var items: [Item]
    
    internal var listCellNodes: [ListCellNode]
    
    private let queueUpdateSubject: BehaviorSubject<(newItems: [Item], animated: Bool, completion: ((Bool) -> Void)?)>
    
    private let disposeBag: DisposeBag
    
    // MARK: Lifecycles ♻️
    
    public init(
        collectionViewLayout: UICollectionViewLayout = UICollectionViewFlowLayout(),
        content: @escaping ItemCell<Item>
    ) {
        self.content = content
        self.items = [Item]()
        self.listCellNodes = [ListCellNode]()
        self.queueUpdateSubject = BehaviorSubject(value: ([], false, nil))
        self.disposeBag = DisposeBag()
        super.init(
            frame: .zero,
            collectionViewLayout: collectionViewLayout,
            layoutFacilitator: nil
        )
        dataSource = proxy
        delegate = proxy
    }
    
    public override func didLoad() {
        super.didLoad()
        bindData()
    }
    
    // MARK: List Updates ⏳
    
    private func bindData() {
        queueUpdateSubject
            .asDriverOnErrorJustComplete()
            .throttle(.milliseconds(200))
            .drive(onNext: { [weak self] newItems, animated, completion in
                guard let self, self.dataSource != nil else { return }
                self.performBatchUpdates(newItems: newItems, animated: animated, completion: completion)
            })
            .disposed(by: disposeBag)
    }
    
    internal func performBatchUpdates(
        newItems: [Item],
        animated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let listDiff: DiffingInterfaceList.Result = getDiffAfterItemsUpdate(newItems: newItems)
        
        guard listDiff.hasChanges else { return }
        
        let listDiffForBatchUpdates: DiffingInterfaceList.Result = listDiff.forBatchUpdates()
        let listCellNodeDiffResult: [ListCellNode] = diffingListCellNode(newItems: newItems, diff: listDiff)
        
        let deletes: IndexSet = listDiffForBatchUpdates.deletes
        let inserts: IndexSet = listDiffForBatchUpdates.inserts
        let updates: IndexSet = listDiffForBatchUpdates.updates
        let moves: [DiffingInterfaceList.MoveIndex] = listDiffForBatchUpdates.moves
        
        if animated {
            performBatch(
                animated: true,
                updates: {
                    listCellNodes = listCellNodeDiffResult
                    deleteSections(deletes)
                    insertSections(inserts)
                    reloadSections(updates)
                    moves.forEach { moveSection($0.from, toSection: $0.to) }
                },
                completion: completion
            )
        } else {
            blockAnimation {
                listCellNodes = listCellNodeDiffResult
                deleteSections(deletes)
                insertSections(inserts)
                reloadSections(updates)
                moves.forEach { moveSection($0.from, toSection: $0.to) }
            } completion: {
                completion?(true)
            }
        }
    }
    
    private func blockAnimation(
        perform code: () -> Void,
        completion: @escaping () -> Void
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        CATransaction.setValue(
            kCFBooleanTrue,
            forKeyPath: kCATransactionDisableActions
        )
        
        code()
        
        CATransaction.commit()
    }
    
    public override func reloadData() {
        assertMainThread("reloadData")
        
        listCellNodes = items.map { createListCellNode(datum: $0) }
        
        super.reloadData()
        view.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Cell Factory 🏭
    
    internal func createListCellNode(datum: Item) -> ListCellNode {
        let listCellNode = content(datum)
        listCellNode.containerNode = self
        return listCellNode
    }
    
    internal func getListCellNodes(at section: Int) -> ListCellNode? {
        return listCellNodes[safe: section]
    }
    
    // MARK: Diffing 🗂️
    
    internal func getDiffAfterItemsUpdate(
        newItems: [Item],
        isUnitTest: Bool = false
    ) -> DiffingInterfaceList.Result {
        assertMainThread("performUpdates")
        
        let oldItems: [Item] = items
        
        #if DEV || DEBUG
            if !newItems.isEmpty, newItems != newItems.removeDuplicates(), !isUnitTest {
                assertionFailure("Duplicate items detected, please use @UniqueElements on your items")
            }
            
            let newItems: [Item] = newItems
        #else
            let newItems: [Item] = newItems.removeDuplicates()
        #endif
        
        items = newItems
        
        return DiffingInterfaceList.diffing(oldArray: oldItems, newArray: newItems)
    }
    
    internal func diffingListCellNode(newItems: [Item], diff: DiffingInterfaceList.Result) -> [ListCellNode] {
        /* The Order of updating collection must followed the rule like this:
         - Create a mutable copy A1
         - Do all reloads
         - Delete from array A1 in descending order
         - Perform inserts in ascending order
         - Move from array A into A1
         https://github.com/Instagram/IGListKit/issues/1006#issuecomment-342579413
         */
        
        var copyListCellNodes: [ListCellNode] = listCellNodes
        
        diff.updates.forEach { index in
            let cellNode: ListCellNode? = copyListCellNodes[safe: index]
            guard let newItem = newItems.first(where: { AnyHashDiffable($0).id == cellNode?.diffableValue?.id })
            else { return }

            let oldItem = items[safe: index].map(AnyHashDiffable.init)

            if let cell = copyListCellNodes[safe: index] as? ListUpdatableCellNode<Item> {
                cell.didUpdate(from: oldItem, to: AnyHashDiffable(newItem))
            } else {
                copyListCellNodes[safe: index] = createListCellNode(datum: newItem)
                copyListCellNodes[safe: index]?.didUpdate(from: oldItem, to: AnyHashDiffable(newItem))
            }
        }
        
        diff.deletes.sorted(by: >).forEach { index in
            copyListCellNodes.remove(at: index)
        }
        
        diff.inserts.sorted(by: <).forEach { index in
            let item = newItems[index]
            let listCellNode = createListCellNode(datum: item)
            listCellNode.didUpdate(from: nil, to: AnyHashDiffable(item))
            copyListCellNodes.insert(listCellNode, at: index)
        }
        
        // ListDiff moves return a pair items intead a single item thus we can't use swap operation
        // in order to achieve the moves, we need to delete `from` index and insert object in `to` index
        let fromMoves = diff.moves.map { $0.to }.sorted(by: >)
        fromMoves.forEach { index in
            if copyListCellNodes.count > index {
                copyListCellNodes.remove(at: index)
            } else {
                assertItemIndexNotFound("diffingListCellNodes-move-delete", index)
            }
        }
        
        diff.moves.forEach { move in
            if let obj = listCellNodes[safe: move.from] {
                if copyListCellNodes.count + 1 > move.to {
                    copyListCellNodes.insert(obj, at: move.to)
                } else {
                    assertItemIndexNotFound("diffingListCellNodes-move-insert-item", move.to)
                }
            } else {
                assertItemIndexNotFound("diffingListCellNodes-move-insert-safeindex", move.from)
            }
        }
        
        return copyListCellNodes
    }
    
    // MARK: Interfaces 🔌
    
    public func performUpdates(
        newItems: [Item],
        animated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        queueUpdateSubject.onNext((newItems, animated, completion))
    }
}
