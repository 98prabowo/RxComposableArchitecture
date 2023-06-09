import AsyncDisplayKit

internal final class ListStoreCellNode: ASCellNode {
    internal let rootNode: ASDisplayNode

    internal init(rootNode: ASDisplayNode) {
        self.rootNode = rootNode
        super.init()
        automaticallyManagesSubnodes = true
        clipsToBounds = false
    }

    override internal func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASWrapperLayoutSpec(layoutElement: rootNode)
    }
}

extension ASCellNode {
    internal static func createEmptyCell() -> ASCellNode {
        let cellNode = ASCellNode()
        cellNode.style.preferredSize = CGSize(width: 0.01, height: 0.01)
        return cellNode
    }
}

extension ListStoreCellNode {
    override public var description: String {
        return "ListStoreCellNode: \(rootNode.description)"
    }

    override public var debugDescription: String {
        return "ListStoreCellNode: \(rootNode.debugDescription)"
    }
}
