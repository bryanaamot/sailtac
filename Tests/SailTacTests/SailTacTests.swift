import XCTest
import OSLog
import Foundation
@testable import SailTac

let logger: Logger = Logger(subsystem: "SailTac", category: "Tests")

@available(macOS 13, *)
final class SailTacTests: XCTestCase {
    func testSailTac() throws {
        logger.log("running testSailTac")
        XCTAssertEqual(1 + 2, 3, "basic test")
        
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SailTac", testData.testModuleName)
    }
    
    func testHaversineDistance() throws {
        let distance = haversineDistance(lat1: 38.0, lon1: 120.0, lat2: 39.0, lon2: 121.0)
        XCTAssertEqual(distance, 141197, accuracy: 1.0) // see https://www.movable-type.co.uk/scripts/latlong.html
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
