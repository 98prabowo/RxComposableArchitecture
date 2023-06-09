import UIKit

internal func safeMainThreadExecution(action: @escaping () -> Void) {
    if Thread.isMainThread {
        action()
    } else {
        DispatchQueue.main.async(execute: action)
    }
}
