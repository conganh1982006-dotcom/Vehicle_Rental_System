import Foundation

class Motorcycle: Vehicle {
    private var engineCC: Int

    init?(vehicleID: String, name: String, brand: String, dailyRate: Double,
          engineCC: Int) {
        guard engineCC > 0 else { return nil }
        self.engineCC = engineCC
        super.init(vehicleID: vehicleID, name: name, brand: brand, dailyRate: dailyRate)
    }

    func getEngineCC() -> Int { engineCC }
    func updateEngineCC(_ value: Int) -> Bool {
        guard value > 0 else { return false }
        engineCC = value
        return true
    }

    func getEngineCategory() -> String {
        if engineCC <= 150 { return "Small engine" }
        if engineCC <= 400 { return "Medium engine" }
        return "Large engine"
    }

    override func getTypeName() -> String { "Motorcycle" }
    override func getSpecifications() -> String {
        "\(engineCC) cc | \(getEngineCategory())"
    }
    override func calculateRentalCost(days: Int) -> Double {
        guard days > 0 else { return 0 }
        // Classroom example: engine category changes the daily rental price.
        let multiplier: Double
        if engineCC <= 150 {
            multiplier = 1.0
        } else if engineCC <= 400 {
            multiplier = 1.15
        } else {
            multiplier = 1.30
        }
        return getDailyRate() * Double(days) * multiplier
    }
}
