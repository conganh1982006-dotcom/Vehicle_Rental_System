import Foundation

class ElectricBicycle: Vehicle {
    private var batteryRangeKm: Double
    private var batteryServiceFee: Double

    init?(vehicleID: String, name: String, brand: String, dailyRate: Double,
          batteryRangeKm: Double, batteryServiceFee: Double) {
        guard batteryRangeKm.isFinite, batteryRangeKm > 0,
              batteryServiceFee.isFinite, batteryServiceFee >= 0 else { return nil }
        self.batteryRangeKm = batteryRangeKm
        self.batteryServiceFee = batteryServiceFee
        super.init(vehicleID: vehicleID, name: name, brand: brand, dailyRate: dailyRate)
    }

    func getBatteryRangeKm() -> Double { batteryRangeKm }
    func getBatteryServiceFee() -> Double { batteryServiceFee }

    func updateBatteryInfo(rangeKm: Double, serviceFee: Double) -> Bool {
        guard rangeKm.isFinite, rangeKm > 0,
              serviceFee.isFinite, serviceFee >= 0 else { return false }
        batteryRangeKm = rangeKm
        batteryServiceFee = serviceFee
        return true
    }

    override func getTypeName() -> String { "Electric Bicycle" }
    override func getSpecifications() -> String {
        "Range: \(Int(batteryRangeKm)) km | Battery fee: \(Int(batteryServiceFee)) VND per rental"
    }
    override func calculateRentalCost(days: Int) -> Double {
        guard days > 0 else { return 0 }
        return getDailyRate() * Double(days) + batteryServiceFee
    }
}
