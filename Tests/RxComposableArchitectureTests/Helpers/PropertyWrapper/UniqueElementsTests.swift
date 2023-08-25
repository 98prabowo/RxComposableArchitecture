import RxCocoa
import RxSwift
import RxTest
import XCTest

@testable import RxComposableArchitecture

internal final class UniqueElementsTests: XCTestCase {
    internal struct Item: Equatable, HashDiffable {
        internal let id: Int
        internal let content: String
    }
    
    internal func testUniqueElement() {
        @UniqueElements var items: [Item] = [
            Item(id: 0, content: "A"),
            Item(id: 1, content: "B"),
            Item(id: 2, content: "C"),
            Item(id: 3, content: "D"),
            Item(id: 4, content: "E")
        ]
        
        XCTAssertEqual(
            items,
            [
                Item(id: 0, content: "A"),
                Item(id: 1, content: "B"),
                Item(id: 2, content: "C"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E")
            ]
        )
        
        items.append(
            contentsOf: [
                Item(id: 0, content: "A"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E"),
                Item(id: 5, content: "F"),
                Item(id: 6, content: "G")
            ]
        )
        
        XCTAssertEqual(
            items,
            [
                Item(id: 0, content: "A"),
                Item(id: 1, content: "B"),
                Item(id: 2, content: "C"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E"),
                Item(id: 5, content: "F"),
                Item(id: 6, content: "G")
            ]
        )
    }
    
    internal func testUniqueElementIdentifiedArray() {
        @UniqueElements var items: IdentifiedArrayOf<Item> = IdentifiedArrayOf(
            [
                Item(id: 0, content: "A"),
                Item(id: 1, content: "B"),
                Item(id: 2, content: "C"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E")
            ]
        )
        
        XCTAssertEqual(
            items,
            [
                Item(id: 0, content: "A"),
                Item(id: 1, content: "B"),
                Item(id: 2, content: "C"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E")
            ]
        )
        
        items.append(
            contentsOf: [
                Item(id: 0, content: "A"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E"),
                Item(id: 5, content: "F"),
                Item(id: 6, content: "G")
            ]
        )
        
        XCTAssertEqual(
            items,
            [
                Item(id: 0, content: "A"),
                Item(id: 1, content: "B"),
                Item(id: 2, content: "C"),
                Item(id: 3, content: "D"),
                Item(id: 4, content: "E"),
                Item(id: 5, content: "F"),
                Item(id: 6, content: "G")
            ]
        )
    }
}

