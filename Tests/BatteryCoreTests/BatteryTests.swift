import XCTest
@testable import BatteryCore

final class BatteryTests: XCTestCase {
    func testAppleSiliconPercentAndSignedDischarge() throws {
        let result = try BatterySnapshot.parse([
            "CurrentCapacity": 42, "MaxCapacity": 100,
            "ExternalConnected": false, "IsCharging": false, "CycleCount": 35,
            "Amperage": NSNumber(value: UInt64(bitPattern: Int64(-1200))), "Voltage": 11000,
            "Temperature": 30015,
            "BatteryData": ["NominalChargeCapacity": 5400, "DesignCapacity": 6000]
        ])
        XCTAssertEqual(result.percent, 42)
        XCTAssertEqual(result.powerWatts!, -13.2, accuracy: 0.001)
        XCTAssertEqual(result.temperatureCelsius!, 27, accuracy: 0.01)
        XCTAssertEqual(result.healthPercent!, 90, accuracy: 0.01)
        XCTAssertFalse(result.pluggedIn)
    }
    func testRawCapacityRatioAndUnknownMetrics() throws {
        let result = try BatterySnapshot.parse(["CurrentCapacity": 3000, "MaxCapacity": 6000])
        XCTAssertEqual(result.percent, 50)
        XCTAssertNil(result.healthPercent)
        XCTAssertNil(result.temperatureCelsius)
        XCTAssertNil(result.powerWatts)
    }
    func testInvalidOrMissingBatteryIsNotReportedAsZero() {
        XCTAssertThrowsError(try BatterySnapshot.parse([:]))
        XCTAssertThrowsError(try BatterySnapshot.parse(["CurrentCapacity": 100, "MaxCapacity": 0]))
    }
    func testHealthClampsAboveDesignAndRejectsBogusTemperature() throws {
        let result = try BatterySnapshot.parse([
            "CurrentCapacity": 101, "MaxCapacity": 100, "Temperature": 0,
            "BatteryData": ["NominalChargeCapacity": 6100, "DesignCapacity": 6000]
        ])
        XCTAssertEqual(result.percent, 100)
        XCTAssertEqual(result.healthPercent, 100)
        XCTAssertNil(result.temperatureCelsius)
    }
}
