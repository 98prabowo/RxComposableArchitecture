import Foundation
@testable import RxComposableArchitecture

internal struct ListNodeTestModel: Equatable, HashDiffable {
    internal let id: Int
    internal var desc: String = ""

    internal static func == (lhs: ListNodeTestModel, rhs: ListNodeTestModel) -> Bool {
        return lhs.id == rhs.id && lhs.desc == rhs.desc
    }

    internal func generateListCellNode() -> ListCellNode {
        return DummyListCellNode()
    }
}
