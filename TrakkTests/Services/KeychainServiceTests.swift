import XCTest
@testable import Trakk

final class KeychainServiceTests: XCTestCase {
    let service = KeychainService()
    let testKey = "test-api-key-12345"

    override func tearDown() {
        service.deleteAPIKey()
        super.tearDown()
    }

    func testSaveAndReadAPIKey() {
        XCTAssertTrue(service.saveAPIKey(testKey))
        XCTAssertEqual(service.readAPIKey(), testKey)
    }

    func testDeleteAPIKey() {
        service.saveAPIKey(testKey)
        service.deleteAPIKey()
        XCTAssertNil(service.readAPIKey())
    }

    func testOverwriteAPIKey() {
        service.saveAPIKey("old-key")
        service.saveAPIKey("new-key")
        XCTAssertEqual(service.readAPIKey(), "new-key")
    }

    func testHasAPIKey() {
        XCTAssertFalse(service.hasAPIKey)
        service.saveAPIKey(testKey)
        XCTAssertTrue(service.hasAPIKey)
    }
}
