import RxSwift
import RxTest
import XCTest

@testable import RxComposableArchitecture

internal final class EffectThrottleTests: XCTestCase {
    internal var disposeBag = DisposeBag()
    internal let scheduler = TestScheduler.default()
    
    internal func testThrottleLatest() {
        var values: [Int] = []
        var effectRuns = 0
        
        func runThrottledEffect(value: Int) {
            struct CancelToken: Hashable {}
            
            Observable.deferred { () -> Observable<Int> in
                effectRuns += 1
                return Observable.just(value)
            }
            .eraseToEffect()
            .throttle(id: CancelToken(), for: .seconds(1), scheduler: scheduler, latest: true)
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        }
        
        runThrottledEffect(value: 1)
        
        // A value emits right away.
        XCTAssertEqual(values, [1])
        
        runThrottledEffect(value: 2)
        
        // A second value is throttled.
        XCTAssertEqual(values, [1])
        
        scheduler.advance(by: 0.25)
        
        runThrottledEffect(value: 3)
        
        scheduler.advance(by: 0.25)
        
        runThrottledEffect(value: 4)
        
        scheduler.advance(by: 0.25)
        
        runThrottledEffect(value: 5)
        
        // A third value is throttled.
        XCTAssertEqual(values, [1])
        
        scheduler.advance(by: 0.25)
        
        // The latest value emits.
        XCTAssertEqual(values, [1, 5])
    }
}
