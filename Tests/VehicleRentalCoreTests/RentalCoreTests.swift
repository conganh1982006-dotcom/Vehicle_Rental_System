import Foundation
import XCTest
@testable import VehicleRentalCore

final class RentalCoreTests: XCTestCase {
    func testPolymorphicPricing() throws {
        let m = RentalManager(seedDemo: true)
        XCTAssertEqual(try m.vehicle(id: "CAR001")?.calculateRentalCost(days: 3), 2_070_000)
        XCTAssertEqual(try m.vehicle(id: "MOT001")?.calculateRentalCost(days: 3), 360_000)
        XCTAssertEqual(try m.vehicle(id: "MOT002")?.calculateRentalCost(days: 3), 720_000)
        XCTAssertEqual(try m.vehicle(id: "EB001")?.calculateRentalCost(days: 3), 510_000)
        let differentKinds: [VehicleKind] = m.vehicles.map(\.kind)
        XCTAssertEqual(Set(differentKinds.map(\.rawValue)).count, 3)
        XCTAssertEqual(m.vehicles.count, 6)
    }

    func testValidationAndEncapsulation() throws {
        XCTAssertNil(Car(id: "", brand: "A", model: "X", dailyRate: 100, seatingCapacity: 5, additionalServiceCharge: 0))
        XCTAssertNil(Motorcycle(id: "M001", brand: "A", model: "X", dailyRate: 100, engineCapacityCC: 0))
        XCTAssertNil(ElectricBicycle(id: "E001", brand: "A", model: "X", dailyRate: 100, batteryRangeKM: -1, batteryServiceFee: 0))
        XCTAssertNil(Customer(id: "C1", fullName: "A", phoneNumber: "abc", email: "a@b.com"))
        let m = RentalManager(seedDemo: true)
        XCTAssertThrowsError(try m.addVehicle(Car(id: "car001", brand: "B", model: "Z", dailyRate: 100, seatingCapacity: 4, additionalServiceCharge: 0)!))
        XCTAssertThrowsError(try m.updateVehicle(id: "CAR001", brand: "", model: "x", dailyRate: 100))
        XCTAssertThrowsError(try m.vehicle(id: "CAR001")?.calculateRentalCost(days: -2))
        XCTAssertThrowsError(try m.registerCustomer(Customer(id: "cus001", fullName: "J", phoneNumber: "0901234567", email: "j@example.com")!))
    }

    func testRentReturnAndHistory() throws {
        let m = RentalManager(seedDemo: true)
        let started = Date(timeIntervalSince1970: 1_700_000_000)
        let r = try m.rentVehicle(vehicleID: "CAR001", customerID: "CUS001", days: 2, at: started)
        XCTAssertEqual(r.totalCost, 1_420_000)
        XCTAssertEqual(m.vehicle(id: "CAR001")?.status, .rented)
        XCTAssertEqual(m.availableVehicles().count, 5)
        XCTAssertEqual(m.rentalHistory(customerID: "CUS001").count, 1)
        XCTAssertThrowsError(try m.rentVehicle(vehicleID: "CAR001", customerID: "CUS002", days: 1))
        XCTAssertThrowsError(try m.returnVehicle(rentalID: r.id, at: started.addingTimeInterval(-1)))
        XCTAssertTrue(r.isActive)
        _ = try m.returnVehicle(rentalID: r.id, at: started.addingTimeInterval(2 * 86400))
        XCTAssertEqual(m.vehicle(id: "CAR001")?.status, .available)
        XCTAssertFalse(r.isActive)
        XCTAssertThrowsError(try m.returnVehicle(rentalID: r.id))
        XCTAssertEqual(try m.totalRentalRevenue(), r.totalCost)
    }

    func testMaintenance() throws {
        let m = RentalManager(seedDemo: true)
        try m.setMaintenance(vehicleID: "MOT001", enabled: true)
        XCTAssertEqual(m.vehicle(id: "MOT001")?.status, .maintenance)
        XCTAssertThrowsError(try m.rentVehicle(vehicleID: "MOT001", customerID: "CUS001", days: 1))
        try m.setMaintenance(vehicleID: "MOT001", enabled: false)
        let r = try m.rentVehicle(vehicleID: "MOT001", customerID: "CUS001", days: 1)
        XCTAssertThrowsError(try m.setMaintenance(vehicleID: "MOT001", enabled: true))
        _ = try m.returnVehicle(rentalID: r.id)
    }

    func testPersistenceRoundTripAndActiveRental() throws {
        let m = RentalManager(seedDemo: true)
        let r = try m.rentVehicle(vehicleID: "EB001", customerID: "CUS002", days: 4)
        let data = try m.exportData()
        let restored = RentalManager()
        try restored.importData(data)
        XCTAssertEqual(restored.vehicles.count, 6)
        XCTAssertEqual(restored.customers.count, 3)
        XCTAssertEqual(restored.records.count, 1)
        XCTAssertEqual(restored.vehicle(id: "EB001")?.status, .rented)
        XCTAssertEqual(restored.rental(id: r.id)?.totalCost, 670_000)
        XCTAssertThrowsError(try restored.rentVehicle(vehicleID: "EB001", customerID: "CUS001", days: 1))
        try restored.returnVehicle(rentalID: r.id)
        XCTAssertEqual(restored.vehicle(id: "EB001")?.status, .available)
        let r2 = try restored.rentVehicle(vehicleID: "EB001", customerID: "CUS001", days: 1)
        XCTAssertNotEqual(r2.id, r.id)
    }

    func testFailedImportDoesNotDestroyCurrentState() throws {
        let m = RentalManager(seedDemo: true)
        XCTAssertThrowsError(try m.importData(Data("not json".utf8)))
        XCTAssertEqual(m.vehicles.count, 6)
        XCTAssertEqual(m.customers.count, 3)
    }

    func testPriceOverflow() {
        let huge = Car(id: "BIG001", brand: "Test", model: "Huge", dailyRate: Int.max,
                       seatingCapacity: 1, additionalServiceCharge: 0)!
        XCTAssertThrowsError(try huge.calculateRentalCost(days: 2))
    }
}
