import RxRelay
import RxSwift
import RxCocoa

/// A `ViewStore` is an object that can observe state changes and send actions. They are most
/// commonly used in views, such as SwiftUI views, UIView or UIViewController, but they can be
/// used anywhere it makes sense to observe state and send actions.
///
/// In SwiftUI applications, a `ViewStore` is accessed most commonly using the `WithViewStore` view.
/// It can be initialized with a store and a closure that is handed a view store and must return a
/// view to be rendered:
///
///     var body: some View {
///       WithViewStore(self.store) { viewStore in
///         VStack {
///           Text("Current count: \(viewStore.count)")
///           Button("Increment") { viewStore.send(.incrementButtonTapped) }
///         }
///       }
///     }
///
/// In UIKit applications a `ViewStore` can be created from a `Store` and then subscribed to for
/// state updates:
///
///     let store: Store<State, Action>
///     let viewStore: ViewStore<State, Action>
///     let disposeBags: DisposeBag
///
///     init(store: Store<State, Action>) {
///       self.store = store
///       self.viewStore = ViewStore(store)
///       self.disposeBags = DisposeBag()
///     }
///
///     func viewDidLoad() {
///       super.viewDidLoad()
///
///       self.viewStore.publisher.count
///         .sink { [weak self] in self?.countLabel.text = $0 }
///         .store(in: &self.cancellables)
///
///       self.viewStore.subscribe(\.count)
///         .drive(countLabel.rx.text)
///         .dispose(by: disposeBags)
///     }
///
///     @objc func incrementButtonTapped() {
///       self.viewStore.send(.incrementButtonTapped)
///     }
///
@dynamicMemberLookup
public final class ViewStore<State, Action> {
    
    /// A publisher of state.
    public let publisher: StorePublisher<State>
    private var viewDisposable: Disposable?
    
    deinit {
        viewDisposable?.dispose()
    }
    
    /// Initializes a view store from a store.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - removeDuplicates: A function to determine when two `State` values are equal. When values are
    ///     equal, repeat view computations are removed.
    public init(
        _ store: Store<State, Action>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) {
        let publisher = store.observable.distinctUntilChanged(isDuplicate)
        self.publisher = StorePublisher(publisher)
        self.stateRelay = BehaviorRelay(value: store.state)
        self._send = store.send
        self.viewDisposable = publisher.subscribe(onNext: { [weak self] in self?.state = $0 })
    }
    
    /// The current state.
    private var stateRelay: BehaviorRelay<State>
    public private(set) var state: State {
        get { return stateRelay.value }
        set { stateRelay.accept(newValue) }
    }
    internal var observable: Observable<State> {
        return stateRelay.asObservable()
    }
    
    internal let _send: (Action) -> Void
    
    /// Returns the resulting value of a given key path.
    public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> LocalState {
        self.state[keyPath: keyPath]
    }
    
    /// Sends an action to the store.
    ///
    /// `ViewStore` is not thread safe and you should only send actions to it from the main thread.
    /// If you are wanting to send actions on background threads due to the fact that the reducer
    /// is performing computationally expensive work, then a better way to handle this is to wrap
    /// that work in an `Effect` that is performed on a background thread so that the result can
    /// be fed back into the store.
    ///
    /// - Parameter action: An action.
    public func send(_ action: Action) {
        self._send(action)
    }
    
    /// Subscribe the state and accept it as a driver.
    ///
    /// - Parameters:
    ///   - toLocalState: A function that transforms `State` into `LocalState`.
    ///   - isDuplicate: A function that equate `LocalState` and `LocalState`.
    /// - Returns: A driver of `LocalState` with option to accept duplicate.
    public func subscribe<LocalState>(
        _ toLocalState: @escaping (State) -> LocalState,
        removeDuplicates isDuplicate: @escaping (LocalState, LocalState) -> Bool
    ) -> Effect<LocalState> {
        return stateRelay
            .map(toLocalState)
            .distinctUntilChanged(isDuplicate)
            .eraseToEffect()
    }
    
    /// Subscribe the state and accept it as a driver.
    ///
    /// - Parameters:
    ///   - toLocalState: A function that transforms `State` into `LocalState`.
    /// - Returns: A driver of `LocalState` that accept different element (always distinctUntilChanged).
    public func subscribe<LocalState>(
        _ toLocalState: @escaping (State) -> LocalState
    ) -> Effect<LocalState> where LocalState: Equatable {
        return stateRelay
            .map(toLocalState)
            .distinctUntilChanged()
            .eraseToEffect()
    }
}

extension ViewStore where State: Equatable {
    public convenience init(_ store: Store<State, Action>) {
        self.init(store, removeDuplicates: ==)
    }
}

/// A publisher of store state.
@dynamicMemberLookup
public struct StorePublisher<State>: ObservableType {
    public typealias Element = State
    public let upstream: Observable<State>
    
    public func subscribe<Observer>(_ observer: Observer) -> Disposable
    where Observer: ObserverType, Element == Observer.Element {
        upstream.subscribe(observer)
    }
    
    internal init(_ upstream: Observable<State>) {
        self.upstream = upstream
    }
    
    /// Returns the resulting publisher of a given key path.
    public subscript<LocalState>(
        dynamicMember keyPath: KeyPath<State, LocalState>
    ) -> StorePublisher<LocalState>
    where LocalState: Equatable {
        StorePublisher<LocalState>(
            self.upstream
                .map { $0[keyPath: keyPath] }
                .distinctUntilChanged()
        )
    }
}

extension ViewStore {
    public func subscribeNeverEqual<LocalState: Equatable>(
        _ toLocalState: @escaping (State) -> NeverEqual<LocalState>
    ) -> Effect<LocalState> {
        return stateRelay
            .map(toLocalState)
            .distinctUntilChanged()
            .map(\.wrappedValue)
            .eraseToEffect()
    }
}
