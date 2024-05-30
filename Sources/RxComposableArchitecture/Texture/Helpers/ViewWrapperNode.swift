import AsyncDisplayKit

/// ASDisplayNode Wrapper for initializing safety-node with a backing view.
internal class ViewWrapperNode<View: UIView>: ASDisplayNode {
    /// Initializer with a block to create the backing view.
    /// - Parameters:
    ///     - createView: The block that will be used to create the backing view.
    ///     - didLoadBlock: The block that will be called after the view created by the viewBlock is loaded.
    internal convenience init(
        createView: @escaping () -> View,
        didLoadBlock: @escaping (ASDisplayNode) -> Void = { _ in }
    ) {
        self.init(viewBlock: createView, didLoad: didLoadBlock)
    }
    
    /// The view object that are wrapped by this node.
    internal var wrappedView: View? {
        assert(Thread.isMainThread)
        guard let view = self.view as? View else {
            assertionFailure("Expecting to convert \(type(of: self.view)) to \(View.description()) but failed.")
            return nil
        }
        
        return view
    }
}
