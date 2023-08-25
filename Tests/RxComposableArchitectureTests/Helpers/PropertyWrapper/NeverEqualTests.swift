import RxCocoa
import RxSwift
import RxTest
import XCTest

@testable import RxComposableArchitecture

internal final class NeverEqualTests: XCTestCase {
    internal var disposeBag = DisposeBag()
    
    internal struct State: Equatable {
        @NeverEqual internal var testState: Stateless?
    }
    
    internal func testNeverEqualSubscription() {
        let reducer = Reducer<State, Void, Void> { state, _, _ in
            state.testState = Stateless()
            return .none
        }
        let store = Store(initialState: State(), reducer: reducer, environment: ())
        let viewStore = ViewStore(store)
        
        var hitCount: Int = 0
        viewStore.subscribeNeverEqual(\.$testState)
            .subscribe(onNext: { _ in
                hitCount += 1
            })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(hitCount, 1)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 2)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 3)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 4)
    }
    
    internal func testNeverEqualMainThreadSubscription() {
        let reducer = Reducer<State, Void, Void> { state, _, _ in
            state.testState = Stateless()
            return .none
        }
        let store = Store(initialState: State(), reducer: reducer, environment: ())
        let viewStore = ViewStore(store)
        
        var hitCount: Int = 0
        viewStore.subscribeNeverEqual(\.$testState)
            .asDriver { _ in Driver.empty() }
            .drive(onNext: { _ in
                hitCount += 1
            })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(hitCount, 1)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 2)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 3)
        
        viewStore.send(())
        
        XCTAssertEqual(hitCount, 4)
    }
    
    internal func testNeverEqualSubscriptionReceiveUpdateFromParent() {
        struct Wrapper: Equatable { var childState = State() }
        let reducer = Reducer<Wrapper, Void, Void> { state, _, _ in
            state.childState.testState = Stateless()
            return .none
        }
        let parentStore = Store(initialState: Wrapper(), reducer: reducer, environment: ())
        let parentViewStore = ViewStore(parentStore)
        
        let childStore = parentStore.scope(state: \.childState)
        let childViewStore = ViewStore(childStore)
        
        var hitCount: Int = 0
        childViewStore.subscribeNeverEqual(\.$testState)
            .subscribe(onNext: { _ in
                hitCount += 1
            })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(hitCount, 1)
        
        parentViewStore.send(())
        
        XCTAssertEqual(hitCount, 2)
        
        parentViewStore.send(())
        
        XCTAssertEqual(hitCount, 3)
        
        parentViewStore.send(())
        
        XCTAssertEqual(hitCount, 4)
    }
    
    internal func testNeverEqualSubscriptionReceiveUpdateFromChild() {
        struct Wrapper: Equatable {
            @NeverEqual var testState: Stateless?
            var childState = State()
        }
        let reducer = Reducer<Wrapper, Void, Void> { state, _, _ in
            state.testState = Stateless()
            return .none
        }
        let parentStore = Store(initialState: Wrapper(), reducer: reducer, environment: ())
        let parentViewStore = ViewStore(parentStore)
        
        let childStore = parentStore.scope(state: \.childState)
        let childViewStore = ViewStore(childStore)
        
        var hitCount: Int = 0
        parentViewStore.subscribeNeverEqual(\.$testState)
            .subscribe(onNext: { _ in
                hitCount += 1
            })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(hitCount, 1)
        
        childViewStore.send(())
        
        XCTAssertEqual(hitCount, 2)
        
        childViewStore.send(())
        
        XCTAssertEqual(hitCount, 3)
        
        childViewStore.send(())
        
        XCTAssertEqual(hitCount, 4)
    }
}
