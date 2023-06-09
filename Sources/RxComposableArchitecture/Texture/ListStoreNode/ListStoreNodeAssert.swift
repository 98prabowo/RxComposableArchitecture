import UIKit

internal func assertMainThread(_ methodName: String) {
    guard !Thread.isMainThread else { return }
    assertionFailure("This method \(methodName) should be called in Main Thread")
}

internal func assertItemIndexNotFound(_ methodName: String, _ index: Int) {
    assertionFailure("\(methodName) - item not available for index: \(index)")
}
