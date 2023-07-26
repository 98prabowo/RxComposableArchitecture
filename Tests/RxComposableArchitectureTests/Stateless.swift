import XCTest

@testable import RxComposableArchitecture

internal final class Stateless: XCTestCase {
    internal func testObjectInitialization() {
        XCTAssertNotNil(Stateless())
    }
}
