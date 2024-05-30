import Foundation

extension Collection {
    /// Safe subscribe collection. If index is out of bound, return nil.
    ///
    /// - Parameters:
    ///     - index: Subscribed index.
    internal subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension MutableCollection {
    /// Safe subscribe collection. If index is out of bound, return nil.
    ///
    /// - Parameters:
    ///     - index: Subscribed index.
    internal subscript(safe index: Index) -> Element? {
        get {
            return indices.contains(index) ? self[index] : nil
        }
        set {
            guard let value = newValue, indices.contains(index) else { return }
            self[index] = value
        }
    }
    
    /// Update all element of the collection for the specific keypath.
    ///
    /// - Parameters:
    ///     - keyPath: Mutated keypath.
    ///     - value: Updated value.
    internal mutating func update<T>(_ keyPath: WritableKeyPath<Element, T>, _ value: T) {
        indices.forEach { self[$0][keyPath: keyPath] = value }
    }
}
