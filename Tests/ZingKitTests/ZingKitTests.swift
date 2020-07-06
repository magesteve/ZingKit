import XCTest
@testable import ZingKit

final class ZingKitTests: XCTestCase {
    func testExample() {
        XCTAssert(ZingKit.kitVersion==1, "Correct Version")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
