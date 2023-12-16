import RxSwift
import TextureSwiftSupport

/**
 Renders different UI components for each enum cases, and you automatically get a scoped store with the type of associated value.

 Let's say you have this enum and the following UI components
```swift
enum ChatWidget: Equatable {
    case text(String)
    case date(Date)
    case image(URL)
}

enum ChatAction: Equatable {
    case text(TextAction)
    case date(DateAction)
    case image(ImageAction)
}

class ChatTextNode: ASDisplayNode {
    init(store: Store<String, TextAction>)
}

class ChatDateNode: ASDisplayNode {
    init(store: Store<Date, DateAction>)
}

class ChatImageNode: ASDisplayNode {
    init(store: Store<URL, ImageAction>)
}
```
 
 Here's how you're going to render them
```swift
let store: Store<ChatState, ChatAction>
let node = SwitchCaseStoreNode(store: store) { matcher in
    matcher.addMatch(state: /ChatState.text, action: ChatAction.text) {
        ChatTextNode(store: $0)
    }

    matcher.addMatch(state: /ChatState.date, action: ChatAction.date) {
        ChatDateNode(store: $0)
    }

    matcher.addMatch(state: /ChatState.image, action: ChatAction.image) {
        ChatImageNode(store: $0)
    }
}
```
 
 ## Pullback Child Reducer on SwitchCaseStoreNode
 Now let's talking about Pullback the child reducer
 
 let's say `ChatTextNode` has reducer called `ChatTextReducer`, so we want to pullback it to parent reducer, how?

 ```swift
 let parentReducer = Reducer<ChatWidget, ChatAction, Void>.combine(
     ChatTextReducer.pullback(
        state: /ChatWidget.text,
        action: /ChatAction.text,
        environment: { $0 }
     ),
     // other reducer
     ...
     ...
 )
 ```
 
 ----
 
 ## Handling Enum inside Struct
 
 What if the State is not directly enum and the enum is inside struct, how i use `SwitchCaseStoreNode` ?
 
 ### Current State and Action
 ```swift
 enum ChatWidget: Equatable {
     case text(String)
     case date(Date)
     case image(URL)
 }
 
 struct ChatState: Equatable {
    let userId: String
    let viewState: ChatWidget // <- enum ChatWidget is place here
 }
 
 enum ChatAction: Equatable {
     case text(TextAction)
     case date(DateAction)
     case image(ImageAction)
 }
 ```
 
 previously when creating `SwitchCaseStoreNode`, we directly use store, but because the ChatWidget is inside struct, we need to direct and scope it.
 
 ### Previously
 ```swift
 let node = SwitchCaseStoreNode(store: store) { matcher in
    ...
 }
 ```
 
 ### Now
 ```swift
 let node = SwitchCaseStoreNode(store: store.scope(\.viewState)) { matcher in
    ...
 }
 ```
 
 what about pullbacking the reducer, let's show you here

 ```swift
 let parentReducer = Reducer<ChatState, ChatAction, Void>.combine(
     ChatTextReducer.pullback(
        state: (\State.viewState) .. (/ChatWidget.text),
        action: /ChatAction.text,
        environment: { $0 }
     ),
     // other reducer
     ...
     ...
 )
 ```
 note:
 * `SwitchCaseStoreNode` is using `OptionalPath` as state parameter requirement on pullback.
 * as you can see, we first need to direct the keypath to `viewState` and then, using `CasePath`, we direct it to the enum case assosiative value.
 * `..` is operator that call function `appending(path:)`, so you can also write like `(\State.viewState).appending(path: /ChatWidget.text))`.
 
 */
public class SwitchCaseStoreNode: ASDisplayNode {
    private let disposeBag = DisposeBag()
    
    private var node: ASDisplayNode?
    
    /*
     The matcher is a hacky way to bind the enum cases to their respective UI. The API looks weird from the inside, but
     should look fine from the API user perspective. If you found a way to make this less weird, please let the core team
     know.
     */
    public struct Matcher<State, Action> {
        public let store: Store<State, Action>
        private let disposeBag: DisposeBag
        private let setNode: (ASDisplayNode) -> Void
        
        fileprivate init(
            store: Store<State, Action>,
            disposeBag: DisposeBag,
            setNode: @escaping (ASDisplayNode) -> Void
        ) {
            self.store = store
            self.disposeBag = disposeBag
            self.setNode = setNode
        }
        
        public func addMatch<LocalState>(
            state: @escaping (State) -> LocalState?,
            createNode: @escaping (Store<LocalState, Action>) -> ASDisplayNode
        ) {
            addMatch(
                state: state,
                action: { $0 },
                createNode: createNode
            )
        }
        
        public func addMatch<LocalState, LocalAction>(
            state: @escaping (State) -> LocalState?,
            action: @escaping (LocalAction) -> Action,
            createNode: @escaping (Store<LocalState, LocalAction>) -> ASDisplayNode
        ) {
            store.scope(
                state: state,
                action: action
            )
            .ifLet { [setNode] scoppedStore in
                let node = createNode(scoppedStore)
                setNode(node)
            }
            .disposed(by: disposeBag)
        }
    }
    
    public init<State, Action>(
        store: Store<State, Action>,
        withAnimation animation: ((_ newNode: ASDisplayNode) -> Void)? = nil,
        matches: @escaping (inout Matcher<State, Action>) -> Void
    ) {
        super.init()
        
        var matcher = Matcher<State, Action>(
            store: store,
            disposeBag: disposeBag
        ) { [weak self] newNode in
            /**
             If dev/user use animation, we need to force texture to display new node, so animation effect can happend.
             
             on default behaviour, new node will only display on screen, when setNeedsLayout is triggered. so `addSubNode` will do the trick.
             */
            
            let block: () -> Void = {
                self?.addSubnode(newNode)
                
                // remove old node
                self?.node?.removeFromSupernode()
                
                // set new node
                self?.node = newNode
                self?.setNeedsLayout()
                
                // if animation exist, execute it
                animation?(newNode)
            }
            
            /**
             Must run block in main thread because `addSubNode` is not thread safe after the node is loaded.
             This is because `addSubNode` when node is loaded will access the underlying `view` which must be on the main thread.
             */
            if self?.isNodeLoaded == true,
               SwitchCaseStoreNodeEnvironment.current.isUsingMainThreadExperiment() {
                safeMainThreadExecution(action: block)
            } else {
                block()
            }
        }
        
        matches(&matcher)
        
        layoutSpecBlock = { [weak self] _, _ in
            guard let node = self?.node else {
                return ASLayoutSpec()
            }
            return ASWrapperLayoutSpec(layoutElement: node)
        }
    }
    
    public convenience init<State, Action>(
        store: Store<State, Action>,
        animateTransition: Bool,
        matches: @escaping (inout Matcher<State, Action>) -> Void
    ) {
        let defaultAnimation: (_ newNode: ASDisplayNode) -> Void = { newNode in
            // display node with 0 alpha first
            newNode.alpha = 0
            
            UIView.animate(withDuration: .T2) {
                // then animate new node apperance
                newNode.alpha = 1
            }
        }
        
        self.init(
            store: store,
            withAnimation: animateTransition ? defaultAnimation : nil,
            matches: matches
        )
    }
}

extension SwitchCaseStoreNode {
    public override var description: String {
        return "SwitchCaseStoreNode: \(node?.description ?? "No Node")"
    }
    
    public override var debugDescription: String {
        return "SwitchCaseStoreNode: \(node.debugDescription)"
    }
}
