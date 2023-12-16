import TextureSwiftSupport

internal final class ListStoreCellNode: ASCellNode {
    internal let rootNode: ASDisplayNode
    
    internal init(rootNode: ASDisplayNode) {
        self.rootNode = rootNode
        super.init()
        automaticallyManagesSubnodes = true
        clipsToBounds = false
    }
    
    internal override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASWrapperLayoutSpec(layoutElement: rootNode)
    }
}

extension ASCellNode {
    internal static var emptyCell: ASCellNode {
        let cellNode = ASCellNode()
        cellNode.style.preferredSize = CGSize(width: 0.01, height: 0.01)
        return cellNode
    }
}

extension ListStoreCellNode {
    public override var description: String {
        return "ListStoreCellNode: \(rootNode.description)"
    }
    
    public override var debugDescription: String {
        return "ListStoreCellNode: \(rootNode.debugDescription)"
    }
}
