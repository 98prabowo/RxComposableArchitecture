import Foundation

public struct SwitchCaseStoreNodeEnvironment {
    internal let isUsingMainThreadExperiment: () -> Bool
    
    public init(isUsingMainThreadExperiment: @escaping () -> Bool) {
        self.isUsingMainThreadExperiment = isUsingMainThreadExperiment
    }
}

extension SwitchCaseStoreNodeEnvironment {
    public static var current: SwitchCaseStoreNodeEnvironment = .mock
    
    internal static let mock: SwitchCaseStoreNodeEnvironment = .init(isUsingMainThreadExperiment: { true })
}
