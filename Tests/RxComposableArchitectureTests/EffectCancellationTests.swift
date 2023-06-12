import RxSwift
import RxTest
import XCTest

@testable import RxComposableArchitecture

internal final class EffectCancellationTests: XCTestCase {
    internal struct CancelToken: Hashable {}
    internal var disposeBag = DisposeBag()
    
    internal override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
    }
    
    internal func testCancellation() {
        var values: [Int] = []
        
        let subject = PublishSubject<Int>()
        let effect = Effect(subject)
            .cancellable(id: CancelToken())
        
        effect
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(values, [])
        subject.onNext(1)
        XCTAssertEqual(values, [1])
        subject.onNext(2)
        XCTAssertEqual(values, [1, 2])
        
        _ = Effect<Never>.cancel(id: CancelToken())
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
        
        subject.onNext(3)
        XCTAssertEqual(values, [1, 2])
    }
    
    internal func testCancelInFlight() {
        var values: [Int] = []
        
        let subject = PublishSubject<Int>()
        Effect(subject)
            .cancellable(id: CancelToken(), cancelInFlight: true)
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(values, [])
        subject.onNext(1)
        XCTAssertEqual(values, [1])
        subject.onNext(2)
        XCTAssertEqual(values, [1, 2])
        
        Effect(subject)
            .cancellable(id: CancelToken(), cancelInFlight: true)
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        
        subject.onNext(3)
        XCTAssertEqual(values, [1, 2, 3])
        subject.onNext(4)
        XCTAssertEqual(values, [1, 2, 3, 4])
    }
    
    internal func testCancellationAfterDelay() {
        var value: Int?
        
        Observable.just(1)
            .delay(.milliseconds(150), scheduler: MainScheduler.instance)
            .eraseToEffect()
            .cancellable(id: CancelToken())
            .subscribe(onNext: { value = $0 })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(value, nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            _ = Effect<Never>.cancel(id: CancelToken())
                .subscribe(onNext: { _ in })
                .disposed(by: self.disposeBag)
        }
        
        _ = XCTWaiter.wait(for: [self.expectation(description: "")], timeout: 0.3)
        
        XCTAssertEqual(value, nil)
    }
    
    internal func testCancellationAfterDelay_WithTestScheduler() {
        let scheduler = TestScheduler.default()
        var value: Int?
        
        Observable.just(1)
            .delay(.seconds(2), scheduler: scheduler)
            .eraseToEffect()
            .cancellable(id: CancelToken())
            .subscribe(onNext: { value = $0 })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(value, nil)
        
        scheduler.advance(by: 1)
        Effect<Never>.cancel(id: CancelToken())
            .subscribe(onNext: { _ in })
            .disposed(by: self.disposeBag)
        
        scheduler.run()
        
        XCTAssertEqual(value, nil)
    }
    
    internal func testCancellablesCleanUp_OnComplete() {
        var isDisposed = false
        
        Observable.just(1)
            .eraseToEffect()
            .cancellable(id: 1)
            .subscribe(onNext: { _ in }, onDisposed: { isDisposed = true })
            .disposed(by: self.disposeBag)
        
        XCTAssertTrue(isDisposed)
    }
    
    internal func testCancellablesCleanUp_OnCancel() {
        let scheduler = TestScheduler.default()
        Observable.just(1)
            .delay(.seconds(1), scheduler: scheduler)
            .eraseToEffect()
            .cancellable(id: 1)
            .subscribe(onNext: { _ in })
            .disposed(by: self.disposeBag)
        
        Effect<Int>
            .cancel(id: 1)
            .subscribe(onNext: { _ in })
            .disposed(by: self.disposeBag)
        
        XCTAssertEqual(0, cancellationCancellables.count)
    }
    
    internal func testDoubleCancellation() {
        var values: [Int] = []
        
        let subject = PublishSubject<Int>()
        let effect = Effect(subject)
            .cancellable(id: CancelToken())
            .cancellable(id: CancelToken())
        
        effect
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(values, [])
        subject.onNext(1)
        XCTAssertEqual(values, [1])
        
        _ = Effect<Never>.cancel(id: CancelToken())
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
        
        subject.onNext(2)
        XCTAssertEqual(values, [1])
    }
    
    internal func testCompleteBeforeCancellation() {
        var values: [Int] = []
        
        let subject = PublishSubject<Int>()
        let effect = Effect(subject)
            .cancellable(id: CancelToken())
        
        effect
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)
        
        subject.onNext(1)
        XCTAssertEqual(values, [1])
        
        subject.onCompleted()
        XCTAssertEqual(values, [1])
        
        _ = Effect<Never>.cancel(id: CancelToken())
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(values, [1])
    }
    
    internal func testConcurrentCancels() {
        let queues = [
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.main),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .background)),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .default)),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .unspecified)),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .userInitiated)),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .userInteractive)),
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .utility)),
        ]
        
        let effect = Effect.merge(
            (1...1_000).map { idx -> Effect<Int> in
                let id = idx % 10
                
                return Effect.merge(
                    Observable.just(idx)
                        .delay(
                            .milliseconds(Int.random(in: 1...100)), scheduler: queues.randomElement()!
                        )
                        .eraseToEffect()
                        .cancellable(id: id),
                    
                    Observable.just(())
                        .delay(
                            .milliseconds(Int.random(in: 1...100)), scheduler: queues.randomElement()!
                        )
                        .flatMap { Effect.cancel(id: id) }
                        .eraseToEffect()
                )
            }
        )
        
        let expectation = self.expectation(description: "wait")
        effect
            .subscribe(onCompleted: { expectation.fulfill() })
            .disposed(by: disposeBag)
        
        self.wait(for: [expectation], timeout: 999)
        
        XCTAssertEqual(0, cancellationCancellables.count)
    }
    
    internal func testNestedCancels() {
        var effect = Observable<Void>.never()
            .eraseToEffect()
            .cancellable(id: 1)
        
        for _ in 1 ... .random(in: 1...1_000) {
            effect = effect.cancellable(id: 1)
        }
        
        effect
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
        
        disposeBag = DisposeBag()
        
        XCTAssertEqual(0, cancellationCancellables.count)
    }
    
    internal func testSharedId() {
        let scheduler = TestScheduler.default()
        
        let effect1 = Observable.just(1)
            .delay(.seconds(1), scheduler: scheduler)
            .eraseToEffect()
            .cancellable(id: "id")
        
        let effect2 = Observable.just(2)
            .delay(.seconds(2), scheduler: scheduler)
            .eraseToEffect()
            .cancellable(id: "id")
        
        var expectedOutput: [Int] = []
        effect1
            .subscribe(onNext: { expectedOutput.append($0) })
            .disposed(by: disposeBag)
        effect2
            .subscribe(onNext: { expectedOutput.append($0) })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(expectedOutput, [])
        scheduler.advance(by: 1)
        XCTAssertEqual(expectedOutput, [1])
        scheduler.advance(by: 1)
        XCTAssertEqual(expectedOutput, [1, 2])
    }
    
    internal func testImmediateCancellation() {
        let scheduler = TestScheduler.default()
        
        var expectedOutput: [Int] = []
        // Don't hold onto cancellable so that it is deallocated immediately.
        let d = Observable.deferred { .just(1) }
            .delay(.seconds(1), scheduler: scheduler)
            .eraseToEffect()
            .cancellable(id: "id")
            .subscribe(onNext: { expectedOutput.append($0) })
        d.dispose()
        
        XCTAssertEqual(expectedOutput, [])
        scheduler.advance(by: 1)
        XCTAssertEqual(expectedOutput, [])
    }
}
