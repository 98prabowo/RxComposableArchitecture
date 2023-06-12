import RxComposableArchitecture
import RxSwift
import RxTest
import XCTest
import os.signpost

internal final class ReducerTests: XCTestCase {
    internal var disposeBag = DisposeBag()
    
    internal func testCallableAsFunction() {
        let reducer = Reducer<Int, Void, Void> { state, _, _ in
            state += 1
            return .none
        }
        
        var state = 0
        _ = reducer.run(&state, (), ())
        XCTAssertEqual(state, 1)
    }
    
    internal func testCombine_EffectsAreMerged() {
        enum Action: Equatable {
            case increment
        }
        
        var fastValue: Int?
        let fastReducer = Reducer<Int, Action, SchedulerType> { state, _, scheduler in
            state += 1
            return Effect.fireAndForget { fastValue = 42 }
                .delay(.seconds(1), scheduler: scheduler)
                .eraseToEffect()
        }
        
        var slowValue: Int?
        let slowReducer = Reducer<Int, Action, SchedulerType> { state, _, scheduler in
            state += 1
            return Effect.fireAndForget { slowValue = 1729 }
                .delay(.seconds(2), scheduler: scheduler)
                .eraseToEffect()
        }
        
        let scheduler = TestScheduler.default()
        let store = TestStore(
            initialState: 0,
            reducer: .combine(fastReducer, slowReducer),
            environment: scheduler
        )
        
        store.assert(
            .send(.increment) {
                $0 = 2
            },
            // Waiting a second causes the fast effect to fire.
            .do { scheduler.advance(by: 1) },
            .do { XCTAssertEqual(fastValue, 42) },
            // Waiting one more second causes the slow effect to fire. This proves that the effects
            // are merged together, as opposed to concatenated.
                .do { scheduler.advance(by: 1) },
            .do { XCTAssertEqual(slowValue, 1729) }
        )
    }
    
    internal func testCombine() {
        enum Action: Equatable {
            case increment
        }
        
        var childEffectExecuted = false
        let childReducer = Reducer<Int, Action, Void> { state, _, _ in
            state += 1
            return Effect.fireAndForget { childEffectExecuted = true }
                .eraseToEffect()
        }
        
        var mainEffectExecuted = false
        let mainReducer = Reducer<Int, Action, Void> { state, _, _ in
            state += 1
            return Effect.fireAndForget { mainEffectExecuted = true }
                .eraseToEffect()
        }
            .combined(with: childReducer)
        
        let store = TestStore(
            initialState: 0,
            reducer: mainReducer,
            environment: ()
        )
        
        store.assert(
            .send(.increment) {
                $0 = 2
            }
        )
        
        XCTAssertTrue(childEffectExecuted)
        XCTAssertTrue(mainEffectExecuted)
    }
    
    internal func testDebug() {
        enum Action: Equatable { case incr, noop }
        struct State: Equatable { var count = 0 }
        
        var logs: [String] = []
        let logsExpectation = self.expectation(description: "logs")
        logsExpectation.expectedFulfillmentCount = 2
        
        let reducer = Reducer<State, Action, Void> { state, action, _ in
            switch action {
            case .incr:
                state.count += 1
                return .none
            case .noop:
                return .none
            }
        }
            .debug("[prefix]") { _ in
                DebugEnvironment(
                    printer: {
                        logs.append($0)
                        logsExpectation.fulfill()
                    }
                )
            }
        
        let store = TestStore(
            initialState: State(),
            reducer: reducer,
            environment: ()
        )
        store.assert(
            .send(.incr) { $0.count = 1 },
            .send(.noop)
        )
        
        self.wait(for: [logsExpectation], timeout: 2)
        
        XCTAssertEqual(
            logs,
            [
                #"""
                [prefix]: received action:
                  Action.incr
                  State(
                −   count: 0
                +   count: 1
                  )
                
                """#,
                #"""
                [prefix]: received action:
                  Action.noop
                  (No state changes)
                
                """#,
            ]
        )
    }
    
    internal func testDebug_ActionFormat_OnlyLabels() {
        enum Action: Equatable { case incr(Bool) }
        struct State: Equatable { var count = 0 }
        
        var logs: [String] = []
        let logsExpectation = self.expectation(description: "logs")
        
        let reducer = Reducer<State, Action, Void> { state, action, _ in
            switch action {
            case let .incr(bool):
                state.count += bool ? 1 : 0
                return .none
            }
        }
            .debug("[prefix]", actionFormat: .labelsOnly) { _ in
                DebugEnvironment(
                    printer: {
                        logs.append($0)
                        logsExpectation.fulfill()
                    }
                )
            }
        
        let viewStore = ViewStore(
            Store(
                initialState: State(),
                reducer: reducer,
                environment: ()
            )
        )
        viewStore.send(.incr(true))
        
        self.wait(for: [logsExpectation], timeout: 2)
        
        XCTAssertEqual(
            logs,
            [
                #"""
                [prefix]: received action:
                  Action.incr
                  State(
                −   count: 0
                +   count: 1
                  )
                
                """#
            ]
        )
    }
}
