import TextureSwiftSupport
import XCTest

@testable import RxComposableArchitecture

internal final class ListNodeTests: XCTestCase {
    internal func testHasChangesDiffing() {
        let oldArray = [
            ListNodeTestModel(id: 1, desc: "1-test")
        ]

        let newArray = [
            ListNodeTestModel(id: 1, desc: "2-test")
        ]

        let diff = DiffingInterfaceList.diffing(oldArray: oldArray, newArray: newArray)
        XCTAssertTrue(diff.hasChanges)
    }

    internal func testHasNoChangesDiffing() {
        let oldArray = [
            ListNodeTestModel(id: 1, desc: "1-test")
        ]

        let newArray = [
            ListNodeTestModel(id: 1, desc: "1-test")
        ]

        let diff = DiffingInterfaceList.diffing(oldArray: oldArray, newArray: newArray)
        XCTAssertFalse(diff.hasChanges)
    }

    internal func testCreateListCellNode() {
        let listNode = generateListNode()
        let datum = ListNodeTestModel(id: 1, desc: "1-test")

        let listCellNode = listNode.createListCellNode(datum: datum)
        listCellNode.didUpdate(from: nil, to: AnyHashDiffable(datum))

        let listCellNodeDiffable = listCellNode.diffableValue
        XCTAssert(listCellNodeDiffable!.isEqual(to: AnyHashDiffable(datum)))
    }

    // MARK: - Delete Items Test

    internal func testDeleteDiffingListCellNode() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 1)
        XCTAssertEqual(diff.deletes, IndexSet([3]))

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 0)
        XCTAssertEqual(diff.inserts, IndexSet())

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testDeleteFromFiveDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(5).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = generateItems(4).map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testDeleteFromTenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(10).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 9, desc: "9-test"),
            ListNodeTestModel(id: 10, desc: "10-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testDeleteFromFifteenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(15).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 7, desc: "7-test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 10, desc: "10-test"),
            ListNodeTestModel(id: 11, desc: "11-test"),
            ListNodeTestModel(id: 12, desc: "12-test"),
            ListNodeTestModel(id: 14, desc: "14-test"),
            ListNodeTestModel(id: 15, desc: "15-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    // MARK: - Insert Items Test

    internal func testInsertDiffingListCellNode() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 7, desc: "7-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 6, desc: "6-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 2)
        XCTAssertEqual(diff.inserts, IndexSet([3, 6]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testInsertFromFiveDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(5).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testInsertFromTenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(10).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = generateItems(14).map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testInsertFromFifteenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(15).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = generateItems(20).map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    // MARK: - Update Items Test

    internal func testUpdateDiffingListCellNode() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 0)
        XCTAssertEqual(diff.inserts, IndexSet())

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 2)
        XCTAssertEqual(diff.updates, IndexSet([1, 2]))

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testUpdateFromFiveDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(5).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testUpdateFromTenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(10).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "test"),
            ListNodeTestModel(id: 6, desc: "test"),
            ListNodeTestModel(id: 7, desc: "test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 9, desc: "9-test"),
            ListNodeTestModel(id: 10, desc: "10-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testUpdateFromFifteenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(15).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 7, desc: "test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 9, desc: "9-test"),
            ListNodeTestModel(id: 10, desc: "test"),
            ListNodeTestModel(id: 11, desc: "11-test"),
            ListNodeTestModel(id: 12, desc: "test"),
            ListNodeTestModel(id: 13, desc: "test"),
            ListNodeTestModel(id: 14, desc: "14-test"),
            ListNodeTestModel(id: 15, desc: "15-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    // MARK: - Move Items Test

    internal func testMoveDiffingListCellNode() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 0)
        XCTAssertEqual(diff.inserts, IndexSet())

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 3)
        XCTAssertEqual(diff.moves[0].from, 4)
        XCTAssertEqual(diff.moves[0].to, 2)
        XCTAssertEqual(diff.moves[1].from, 2)
        XCTAssertEqual(diff.moves[1].to, 3)
        XCTAssertEqual(diff.moves[2].from, 3)
        XCTAssertEqual(diff.moves[2].to, 4)
    }

    internal func testMoveFromFiveDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(5).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testMoveFromTenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(10).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 7, desc: "7-test"),
            ListNodeTestModel(id: 9, desc: "9-test"),
            ListNodeTestModel(id: 10, desc: "10-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    internal func testMoveFromFifteenDiffingListCellNode() {
        let oldItems: [AnyHashDiffable] = generateItems(15).map { AnyHashDiffable($0) }

        let newItems: [AnyHashDiffable] = [
            ListNodeTestModel(id: 13, desc: "13-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 12, desc: "12-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 15, desc: "15-test"),
            ListNodeTestModel(id: 7, desc: "7-test"),
            ListNodeTestModel(id: 8, desc: "8-test"),
            ListNodeTestModel(id: 9, desc: "9-test"),
            ListNodeTestModel(id: 10, desc: "10-test"),
            ListNodeTestModel(id: 11, desc: "11-test"),
            ListNodeTestModel(id: 14, desc: "14-test")
        ].map { AnyHashDiffable($0) }

        let diffingResult = diffingListCellNodeHelper(oldItems: oldItems, newItems: newItems)

        for index in 0 ..< newItems.count {
            XCTAssert(diffingResult[index].diffableValue!.isEqual(to: newItems[index]))
        }
    }

    // MARK: - Duplicate Items Test

    internal func testDeleteDiffingWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 1, desc: "1-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 1)
        XCTAssertEqual(diff.deletes, IndexSet([3]))

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 8)
        XCTAssertEqual(diff.inserts, IndexSet([2, 5, 6, 7, 8, 9, 10, 11]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testInsertDiffingWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 7, desc: "7-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 6, desc: "6-test"),
            ListNodeTestModel(id: 2, desc: "2-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 5)
        XCTAssertEqual(diff.inserts, IndexSet([3, 6, 7, 8, 9]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testUpdateDiffingWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 2, desc: "test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 6)
        XCTAssertEqual(diff.inserts, IndexSet([3, 6, 7, 8, 9, 10]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 2)
        XCTAssertEqual(diff.updates, IndexSet([1, 2]))

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testMoveDiffingWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        )

        // Delete result assertion
        XCTAssertEqual(diff.deletes.count, 0)
        XCTAssertEqual(diff.deletes, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 15)
        XCTAssertEqual(diff.inserts, IndexSet([2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 3)
        XCTAssertEqual(diff.moves[0].from, 4)
        XCTAssertEqual(diff.moves[0].to, 4)
        XCTAssertEqual(diff.moves[1].from, 2)
        XCTAssertEqual(diff.moves[1].to, 13)
        XCTAssertEqual(diff.moves[2].from, 3)
        XCTAssertEqual(diff.moves[2].to, 14)
    }

    // MARK: - Batch Update Test

    internal func testBatchUpdateWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 2, desc: "test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 3, desc: "test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        ).forBatchUpdates()

        // Delete result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 6)
        XCTAssertEqual(diff.inserts, IndexSet([3, 6, 7, 8, 9, 10]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 0)
        XCTAssertEqual(diff.moves, [])
    }

    internal func testBatchUpdateMoveWithDuplicateItems() {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: generateItems(5),
            animated: false
        )

        let newItems = [
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 1, desc: "1-test"),
            ListNodeTestModel(id: 2, desc: "2-test"),
            ListNodeTestModel(id: 5, desc: "test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 3, desc: "3-test"),
            ListNodeTestModel(id: 4, desc: "test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 5, desc: "5-test"),
            ListNodeTestModel(id: 4, desc: "4-test"),
            ListNodeTestModel(id: 5, desc: "5-test")
        ]

        let diff = listNode.getDiffAfterItemsUpdate(
            newItems: newItems,
            isUnitTest: true
        ).forBatchUpdates()

        // Delete result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Insert result assertion
        XCTAssertEqual(diff.inserts.count, 17)
        XCTAssertEqual(diff.inserts, IndexSet([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19]))

        // Update result assertion
        XCTAssertEqual(diff.updates.count, 0)
        XCTAssertEqual(diff.updates, IndexSet())

        // Move result assertion
        XCTAssertEqual(diff.moves.count, 1)
        XCTAssertEqual(diff.moves[0].from, 2)
        XCTAssertEqual(diff.moves[0].to, 13)
    }

    private func generateItems(_ count: Int) -> [ListNodeTestModel] {
        var items: [ListNodeTestModel] = []

        for index in 0 ..< count {
            let id = index + 1
            items.append(.init(id: id, desc: "\(id)-test"))
        }

        return items
    }

    private func diffingListCellNodeHelper(oldItems: [AnyHashDiffable], newItems: [AnyHashDiffable]) -> [ListCellNode] {
        let listNode = generateListNode()

        listNode.performBatchUpdates(
            newItems: oldItems.map { $0.base as! ListNodeTestModel },
            animated: false
        )

        let diff = DiffingInterfaceList.diffing(
            oldArray: oldItems,
            newArray: newItems.removeDuplicates()
        )

        return listNode.diffingListCellNode(
            newItems: newItems.map { $0.base as! ListNodeTestModel },
            diff: diff
        )
    }

    private func generateListNode() -> ListNode<ListNodeTestModel> {
        return ListNode<ListNodeTestModel> { model in
            model.generateListCellNode()
        }
    }
}
