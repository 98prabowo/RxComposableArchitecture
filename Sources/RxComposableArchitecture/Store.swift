import Foundation
import RxRelay
import RxSwift

/// A store represents the runtime that powers the application. It is the object that you will pass
/// around to views that need to interact with the application.
///
/// You will typically construct a single one of these at the root of your application, and then use
/// the `scope` method to derive more focused stores that can be passed to subviews.
public final class Store<State, Action> {
    
    private var synchronousActionsToSend: [Action] = []
    private var isSending = false
    
    private var parentDisposable: Disposable?
    internal var effectDisposables = CompositeDisposable()
    
    private let reducer: (inout State, Action) -> Effect<Action>
    
    private var stateRelay: BehaviorRelay<State>
    public private(set) var state: State {
        get { return stateRelay.value }
        set { stateRelay.accept(newValue) }
    }
    internal var observable: Observable<State> {
        return stateRelay.asObservable()
    }
    
    deinit {
        parentDisposable?.dispose()
        effectDisposables.dispose()
    }
    
    /// Initializes a store from an initial state, a reducer, and an environment.
    ///
    /// - Parameters:
    ///   - initialState: The state to start the application in.
    ///   - reducer: The reducer that powers the business logic of the application.
    ///   - environment: The environment of dependencies for the application.
    public convenience init<Environment>(
        initialState: State,
        reducer: Reducer<State, Action, Environment>,
        environment: Environment
    ) {
        self.init(
            initialState: initialState,
            reducer: { reducer.run(&$0, $1, environment) }
        )
    }
    
    /// Scopes the store to one that exposes local state and actions.
    ///
    /// This can be useful for deriving new stores to hand to child views in an application. For
    /// example:
    ///
    ///     // Application state made from local states.
    ///     struct AppState { var login: LoginState, ... }
    ///     struct AppAction { case login(LoginAction), ... }
    ///
    ///     // A store that runs the entire application.
    ///     let store = Store(initialState: AppState(), reducer: appReducer, environment: ())
    ///
    ///     // Construct a login view by scoping the store to one that works with only login domain.
    ///     let loginView = LoginView(
    ///       store: store.scope(
    ///         state: { $0.login },
    ///         action: { AppAction.login($0) }
    ///       )
    ///     )
    ///
    /// - Parameters:
    ///   - toLocalState: A function that transforms `State` into `LocalState`.
    ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
    /// - Returns: A new store with its domain (state and action) transformed.
    public func scope<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction> {
        let localStore = Store<LocalState, LocalAction>(
            initialState: toLocalState(self.state),
            reducer: { localState, localAction in
                self.send(fromLocalAction(localAction))
                localState = toLocalState(self.state)
                return .none
            }
        )
        
        localStore.parentDisposable = self.observable
            .subscribe(onNext: { [weak localStore] newValue in
                guard let localStore = localStore else { return }
                localStore.state = toLocalState(newValue)
            })
        
        return localStore
    }
    
    /// Scopes the store to one that exposes local state.
    ///
    /// - Parameter toLocalState: A function that transforms `State` into `LocalState`.
    /// - Returns: A new store with its domain (state and action) transformed.
    public func scope<LocalState>(
        state toLocalState: @escaping (State) -> LocalState
    ) -> Store<LocalState, Action> {
        self.scope(state: toLocalState, action: { $0 })
    }
    
    /// Scopes the store to a publisher of stores of more local state and local actions.
    ///
    /// - Parameters:
    ///   - toLocalState: A function that transforms a publisher of `State` into a publisher of
    ///     `LocalState`.
    ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
    /// - Returns: A publisher of stores with its domain (state and action) transformed.
    public func scope<LocalState, LocalAction>(
        state toLocalState: @escaping (Observable<State>) -> Observable<LocalState>,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Observable<Store<LocalState, LocalAction>> {
        
        func extractLocalState(_ state: State) -> LocalState? {
            var localState: LocalState?
            _ = toLocalState(Observable.just(state)).subscribe(onNext: { localState = $0 })
            return localState
        }
        
        return toLocalState(self.observable)
            .map { localState in
                let localStore = Store<LocalState, LocalAction>(
                    initialState: localState,
                    reducer: { localState, localAction in
                        self.send(fromLocalAction(localAction))
                        localState = extractLocalState(self.state) ?? localState
                        return .none
                    })
                
                localStore.parentDisposable = self.observable
                    .subscribe(onNext: { [weak localStore] state in
                        guard let localStore = localStore else { return }
                        localStore.state = extractLocalState(state) ?? localStore.state
                    })
                
                return localStore
            }
    }
    
    /// Scopes the store to a publisher of stores of more local state and local actions.
    ///
    /// - Parameter toLocalState: A function that transforms a publisher of `State` into a publisher
    ///   of `LocalState`.
    /// - Returns: A publisher of stores with its domain (state and action)
    ///   transformed.
    public func scope<LocalState>(
        state toLocalState: @escaping (Observable<State>) -> Observable<LocalState>
    ) -> Observable<Store<LocalState, Action>> {
        self.scope(state: toLocalState, action: { $0 })
    }
    
    internal func send(_ action: Action) {
        self.synchronousActionsToSend.append(action)
        
        while !self.synchronousActionsToSend.isEmpty {
            let action = self.synchronousActionsToSend.removeFirst()
            
            if self.isSending {
                assertionFailure(
          """
          The store was sent the action \(debugCaseOutput(action)) while it was already
          processing another action.
          
          This can happen for a few reasons:
          
          * The store was sent an action recursively. This can occur when you run an effect \
          directly in the reducer, rather than returning it from the reducer. Check the stack (⌘7) \
          to find frames corresponding to one of your reducers. That code should be refactored to \
          not invoke the effect directly.
          
          * The store has been sent actions from multiple threads. The `send` method is not \
          thread-safe, and should only ever be used from a single thread (typically the main \
          thread). Instead of calling `send` from multiple threads you should use effects to \
          process expensive computations on background threads so that it can be fed back into the \
          store.
          """
                )
            }
            self.isSending = true
            let effect = self.reducer(&self.state, action)
            self.isSending = false
            
            var didComplete = false
            var isProcessingEffects = true
            var disposeKey: CompositeDisposable.DisposeKey?
            
            let effectDisposable = effect.subscribe(
                onNext: { [weak self] action in
                    if isProcessingEffects {
                        self?.synchronousActionsToSend.append(action)
                    } else {
                        self?.send(action)
                    }
                },
                onError: { err in
                    assertionFailure("Error during effect handling: \(err.localizedDescription)")
                },
                onCompleted: { [weak self] in
                    didComplete = true
                    if let disposeKey = disposeKey {
                        self?.effectDisposables.remove(for: disposeKey)
                    }
                }
            )
            
            isProcessingEffects = false
            
            if !didComplete {
                disposeKey = effectDisposables.insert(effectDisposable)
            }
        }
    }
    
    /// Returns a "stateless" store by erasing state to `Void`.
    public var stateless: Store<Void, Action> {
        self.scope(state: { _ in () })
    }
    
    /// Returns an "actionless" store by erasing action to `Never`.
    public var actionless: Store<State, Never> {
        func absurd<A>(_ never: Never) -> A {}
        return self.scope(state: { $0 }, action: absurd)
    }
    
    private init(
        initialState: State,
        reducer: @escaping (inout State, Action) -> Effect<Action>
    ) {
        self.stateRelay = BehaviorRelay(value: initialState)
        self.reducer = reducer
        self.state = initialState
    }
}

extension Store where State: Collection, State.Element: HashDiffable, State: Equatable, State.Element: Equatable {
    /**
     A version of scope that scope an collection of sub store.

     This is kinda a version of `ForEachStoreNode`, not composing `WithViewStore` but creates the sub store.

     ## Example
     ```
     struct AppState { var todos: [Todo] }
     struct AppAction { case todo(index: Int, action: TodoAction }

     store.subscribe(\.todos)
        .drive(onNext: { todos in
            self.todoNodes = zip(todos.indices, todos).map { (offset, _) in
                TodoNode(with: store.scope(
                    identifier: identifier,
                    action: Action.todo(index:action:)
                )
            }
        })
        .disposed(by: disposeBag)
     ```

     But with example above, you created the entire node again and again and it's not the efficient way.
     You can do some diffing and only creating spesific index, and rest is handle by diffing.

     - Parameters:
        - identifier: the identifier from `IdentifierType` make sure index is in bounds of the collection
        - action: A function to transform `LocalAction` to `Action`. `LocalAction` should have `(CollectionIndex, LocalAction)` signature.

     - Returns: A new store with its domain (state and domain) transformed based on the index you set
     */
    public func scope<LocalAction>(
        at identifier: State.Element.IdentifierType,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<State.Element, LocalAction>? {
        let toLocalState: (State.Element.IdentifierType, State) -> State.Element? = { identifier, state in
            /**
             if current state is IdentifiedArray, use pre exist subscript by identifier, to improve performance
             */
            if let identifiedArray = state as? IdentifiedArrayOf<State.Element> {
                return identifiedArray[id: identifier]
            } else {
                return state.first(where: { $0.id == identifier })
            }
        }
        
        guard let element = toLocalState(identifier, state) else { return nil }

        let localStore = Store<State.Element, LocalAction>(
            initialState: element,
            reducer: Reducer { localState, localAction, _ in
                self.send(fromLocalAction(localAction))
                guard let finalState = toLocalState(identifier, self.state) else {
                    return .none
                }

                localState = finalState
                return .none
            },
            environment: ()
        )

        // reflect changes on store parent to local store
        localStore.parentDisposable = stateRelay
            .distinctUntilChanged()
            .flatMapLatest { newValue -> Observable<State.Element> in
                guard let newElement = toLocalState(identifier, newValue) else {
                    return .empty()
                }

                return .just(newElement)
            }
            .subscribe(onNext: { [weak localStore] newValue in
                localStore?.state = newValue
            })

        return localStore
    }
}
