import Foundation

public protocol HashDiffable: Sendable {
    associatedtype IdentifierType: Hashable, Sendable
    var id: Self.IdentifierType { get }
    func isEqual(to source: Self) -> Bool
}

public extension HashDiffable where Self: Hashable {
    /// The `self` value as an identifier for difference calculation.
    var id: Self {
        return self
    }
}

extension HashDiffable where Self: Equatable {
    public func isEqual(to source: Self) -> Bool {
        return self == source
    }
}
