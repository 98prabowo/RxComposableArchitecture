import Foundation

public struct OptionalPath<Root, Value> {
    private let _extract: (Root) -> Value?
    private let _set: (inout Root, Value) -> Void
    
    internal init(
        extract: @escaping (Root) -> Value?,
        set: @escaping (inout Root, Value) -> Void
    ) {
        _extract = extract
        _set = set
    }
    
    public func extract(from root: Root) -> Value? {
        _extract(root)
    }
    
    public func set(into root: inout Root, _ value: Value) {
        _set(&root, value)
    }
    
    public init(_ keypath: WritableKeyPath<Root, Value?>) {
        self.init(
            extract: { $0[keyPath: keypath] },
            set: { $0[keyPath: keypath] = $1 }
        )
    }
    
    public init(_ casePath: AnyCasePath<Root, Value>) {
        self.init(
            extract: casePath.extract(from:),
            set: { $0 = casePath.embed($1) }
        )
    }
    
    public func appending<AppendedValue>(
        path: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        .init(
            extract: { self.extract(from: $0).flatMap(path.extract(from:)) },
            set: { root, appendedValue in
                guard var value = self.extract(from: root) else { return }
                path.set(into: &value, appendedValue)
                self.set(into: &root, value)
            }
        )
    }
    
    public func appending<AppendedValue>(
        path: AnyCasePath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        appending(path: .init(path))
    }
    
    public func appending<AppendedValue>(
        path: WritableKeyPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        .init(
            extract: { self.extract(from: $0).map { $0[keyPath: path] } },
            set: { root, appendedValue in
                guard var value = self.extract(from: root) else { return }
                value[keyPath: path] = appendedValue
                self.set(into: &root, value)
            }
        )
    }
    
    public func appending<AppendedValue>(
        path: WritableKeyPath<Value, AppendedValue?>
    ) -> OptionalPath<Root, AppendedValue> {
        appending(path: .init(path))
    }
}

extension AnyCasePath {
    public func appending<AppendedValue>(
        path: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        OptionalPath(self).appending(path: path)
    }
    
    public func appending<AppendedValue>(
        path: WritableKeyPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        OptionalPath(self).appending(path: path)
    }
    
    public func appending<AppendedValue>(
        path: WritableKeyPath<Value, AppendedValue?>
    ) -> OptionalPath<Root, AppendedValue> {
        OptionalPath(self).appending(path: path)
    }
}

extension WritableKeyPath {
    public func appending<AppendedValue>(
        path: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        OptionalPath(
            extract: { path.extract(from: $0[keyPath: self]) },
            set: { root, appendedValue in
                path.set(into: &root[keyPath: self], appendedValue)
            }
        )
    }
    
    public func appending<AppendedValue>(
        path: AnyCasePath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        appending(path: .init(path))
    }
}

extension OptionalPath where Root == Value {
    public static var `self`: OptionalPath {
        OptionalPath(.self)
    }
}

extension OptionalPath where Root == Value? {
    public static var some: OptionalPath {
        .init(/Optional.some)
    }
}

// MARK: - Operator

precedencegroup OptionalPathCompositionPrecedence {
    associativity: right
}

infix operator ..: OptionalPathCompositionPrecedence

extension OptionalPath {
    /// Returns a new Optional path created by appending the given optional path to this one.
    ///
    /// The operator version of `OptionalPath.appending(path:)`. Use this method to extend this optional path to the value type of another path.
    ///
    /// - Parameters:
    ///   - lhs: A optional path from a root to a value.
    ///   - rhs: A optional path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first optional path's root to the second optional path's value.
    public static func .. <AppendedValue>(
        lhs: OptionalPath,
        rhs: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }
    
    /// Returns a new Optional path created by appending the given writeable path to this one.
    ///
    /// The operator version of `OptionalPath.appending(path:)`. Use this method to extend this optional path to the value type of another path.
    ///
    /// - Parameters:
    ///   - lhs: A optional path from a root to a value.
    ///   - rhs: A writeable path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first optional path's root to the second writeable path's value.
    public static func .. <AppendedValue>(
        lhs: OptionalPath,
        rhs: WritableKeyPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }

    /// Returns a new Optional path created by appending the given case path to this one.
    ///
    /// The operator version of `OptionalPath.appending(path:)`. Use this method to extend this optional path to the value type of another path.
    ///
    /// - Parameters:
    ///   - lhs: A optional path from a root to a value.
    ///   - rhs: A case path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first optional path's root to the second case path's value.
    public static func .. <AppendedValue>(
        lhs: OptionalPath,
        rhs: AnyCasePath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }
}

extension WritableKeyPath {
    /// Returns a new Optional path created by appending the given optional path to this one.
    ///
    /// The operator version of `WritableKeyPath.appending(path:)`. Use this method to extend this writeable path to the value type of another optional path.
    ///
    /// - Parameters:
    ///   - lhs: A writeable path from a root to a value.
    ///   - rhs: A optional path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first writeable path's root to the second optional path's value.
    public static func .. <AppendedValue>(
        lhs: WritableKeyPath,
        rhs: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }

    /// Returns a new Optional path created by appending the given case path to this one.
    ///
    /// The operator version of `WritableKeyPath.appending(path:)`. Use this method to extend this writeable path to the value type of another case path.
    ///
    /// - Parameters:
    ///   - lhs: A writeable path from a root to a value.
    ///   - rhs: A case path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first writeable path's root to the second case path's value.
    public static func .. <AppendedValue>(
        lhs: WritableKeyPath,
        rhs: AnyCasePath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }
}

extension AnyCasePath {
    /// Returns a new Optional path created by appending the given optional path to this one.
    ///
    /// The operator version of `CasePath.appending(path:)`. Use this method to extend this case path to the value type of another optional path.
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: A optional path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first case path's root to the second optional path's value.
    public static func .. <AppendedValue>(
        lhs: AnyCasePath<Root, Value>,
        rhs: OptionalPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }

    /// Returns a new Optional path created by appending the given optional path to this one.
    ///
    /// The operator version of `CasePath.appending(path:)`. Use this method to extend this case path to the value type of another writeable path.
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: A writeable path from the first optional path's value to some other appended value.
    /// - Returns: A new optional path from the first case path's root to the second writeable path's value.
    public static func .. <AppendedValue>(
        lhs: AnyCasePath<Root, Value>,
        rhs: WritableKeyPath<Value, AppendedValue>
    ) -> OptionalPath<Root, AppendedValue> {
        return lhs.appending(path: rhs)
    }
}
