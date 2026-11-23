import Foundation

// The parent class contains information shared by all vehicle types.
class Vehicle: Identifiable {
    private let vehicleID: String
    private var name: String
    private var brand: String
    private var dailyRate: Double
    private var available = true

    var id: String { vehicleID }

    init?(vehicleID: String, name: String, brand: String, dailyRate: Double) {
        let cleanID = vehicleID.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty, !cleanName.isEmpty, !cleanBrand.isEmpty,
              dailyRate.isFinite, dailyRate > 0 else { return nil }
        self.vehicleID = cleanID
        self.name = cleanName
        self.brand = cleanBrand
        self.dailyRate = dailyRate
    }

    func getVehicleID() -> String { vehicleID }
    func getName() -> String { name }
    func getBrand() -> String { brand }
    func getDailyRate() -> Double { dailyRate }
    func isAvailable() -> Bool { available }

    func updateCommonInfo(name: String, brand: String, dailyRate: Double) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanBrand.isEmpty,
              dailyRate.isFinite, dailyRate > 0 else { return false }
        self.name = cleanName
        self.brand = cleanBrand
        self.dailyRate = dailyRate
        return true
    }

    // Only RentalManager should call these state-changing operations.
    func markRented() -> Bool {
        guard available else { return false }
        available = false
        return true
    }

    func markReturned() -> Bool {
        guard !available else { return false }
        available = true
        return true
    }

    // Child classes override these methods to define specific behavior.
    func getTypeName() -> String { "Vehicle" }
    func getSpecifications() -> String { "General vehicle" }
    func calculateRentalCost(days: Int) -> Double {
        guard days > 0 else { return 0 }
        return dailyRate * Double(days)
    }
}
