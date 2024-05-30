import TextureSwiftSupport

internal class ListNodeProxy<Item: HashDiffable & Equatable>: NSObject, ASCollectionDataSource, ASCollectionDelegate {
    private weak var listNode: ListNode<Item>?
    
    internal init(listNode: ListNode<Item>) {
        self.listNode = listNode
        super.init()
    }
    
    // MARK: Collection Data Source
    
    internal func numberOfSections(in: ASCollectionNode) -> Int {
        guard let listNode else { return 0 }
        return listNode.listCellNodes.count
    }
    
    internal func collectionNode(_: ASCollectionNode, numberOfItemsInSection: Int) -> Int {
        return 1
    }
    
    internal func collectionNode(_: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        guard let listCellNode = listNode?.getListCellNodes(at: indexPath.section) else { return EmptyListCellNode() }
        return listCellNode
    }
    
    // MARK: Collection Delegate
    
    internal func collectionNode(_: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        guard let listCellNode = listNode?.getListCellNodes(at: indexPath.section) else { return }
        listCellNode.didSelectItem(at: indexPath.section)
    }
}
