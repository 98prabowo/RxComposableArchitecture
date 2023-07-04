import Foundation

public protocol WritablePath {
    associatedtype Root
    associatedtype Value
    func extract(from root: Root) -> Value?
    func set(into root: inout Root, _ value: Value)
}

extension WritableKeyPath: WritablePath {
    public func extract(from root: Root) -> Value? {
        root[keyPath: self]
    }
    
    public func set(into root: inout Root, _ value: Value) {
        root[keyPath: self] = value
    }
}

extension CasePath: WritablePath {
    public func set(into root: inout Root, _ value: Value) {
        root = embed(value)
    }
}
