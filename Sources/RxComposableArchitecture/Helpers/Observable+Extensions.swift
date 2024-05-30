import RxCocoa
import RxSwift

extension ObservableType {
    /// Transform `Observable` into a `Driver`. If on error will return empty.
    ///
    /// - Returns: Driver trait.
    public func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { _ in Driver.empty() }
    }
}
