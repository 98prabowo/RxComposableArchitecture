import TextureSwiftSupport

public struct LayoutSpecOptions {
    /// The direction children are stacked in
    public var stackDirection: ASStackLayoutDirection
    /// Whether children are stacked into a single or multiple lines.
    public var flexWrap: ASStackLayoutFlexWrap
    /// If no children are flexible, how should this spec justify its children in the available space?
    public var justifyContent: ASStackLayoutJustifyContent
    /// Orientation of children along cross axis
    public var alignItems: ASStackLayoutAlignItems
    /// If the stack spreads on multiple lines using flexWrap, the amount of space between lines.
    public var lineSpacing: CGFloat
    /// The spacing between the children
    public var spacing: CGFloat
    /// Inside insets
    public var insets: UIEdgeInsets
    
    /**
     `LayoutSpecOptions` is used to configure `ForEachStoreNode` layoutSpec

     - Parameters:
        - stackDirection: The direction children are stacked in
        - flexWrap: Whether children are stacked into a single or multiple lines.
        - justifyContent: If no children are flexible, how should this spec justify its children in the available space?
        - alignItems: Orientation of children along cross axis
        - lineSpacing: If the stack spreads on multiple lines using flexWrap, the amount of space between lines
        - spacing: The spacing between the children
        - insets: Inside insets
     */
    public init(
        stackDirection: ASStackLayoutDirection = .vertical,
        flexWrap: ASStackLayoutFlexWrap = .noWrap,
        justifyContent: ASStackLayoutJustifyContent = .start,
        alignItems: ASStackLayoutAlignItems = .stretch,
        lineSpacing: CGFloat = .zero,
        spacing: CGFloat = 8,
        insets: UIEdgeInsets = .zero
    ) {
        self.stackDirection = stackDirection
        self.flexWrap = flexWrap
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.lineSpacing = lineSpacing
        self.spacing = spacing
        self.insets = insets
    }
}
