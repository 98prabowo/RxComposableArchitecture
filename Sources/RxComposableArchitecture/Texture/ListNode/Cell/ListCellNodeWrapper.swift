import TextureSwiftSupport

/**
 A ListCellNode Wrapper of ASDisplayNode

 Use this class to directly wrap your ASDisplayNode on listnode creation without having to create a new dedicated file just to wrap them.

 # Example #
 ```
 private lazy var listNode = ListNode<ComponentType> { component in
    switch component {
        case let .coolWidget(data):
            let node = CoolWidgetNode(data: data)
            return ListCellNodeWrapper<CoolWidgetNode>(node: node)
    }
 }
 ```
 */
public final class ListCellNodeWrapper<Node: ASDisplayNode>: ListCellNode {
    public let node: Node

    public init(node: Node) {
        self.node = node
        super.init()
        automaticallyManagesSubnodes = true
        clipsToBounds = false
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASWrapperLayoutSpec(layoutElement: node)
    }
}
