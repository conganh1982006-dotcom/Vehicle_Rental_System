import Foundation

class Car: Vehicle {
    private var seatCount: Int
    private var serviceCharge: Double

    init?(vehicleID: String, name: String, brand: String, dailyRate: Double,
          seatCount: Int, serviceCharge: Double) {
        guard seatCount > 0, serviceCharge.isFinite, serviceCharge >= 0 else { return nil }
        self.seatCount = seatCount
        self.serviceCharge = serviceCharge
        super.init(vehicleID: vehicleID, name: name, brand: brand, dailyRate: dailyRate)
    }

    func getSeatCount() -> Int { seatCount }
    func getServiceCharge() -> Double { serviceCharge }

    func updateCarInfo(seatCount: Int, serviceCharge: Double) -> Bool {
        guard seatCount > 0, serviceCharge.isFinite, serviceCharge >= 0 else { return false }
        self.seatCount = seatCount
        self.serviceCharge = serviceCharge
        return true
    }

    override func getTypeName() -> String { "Car" }
    override func getSpecifications() -> String {
        "\(seatCount) seats | Service charge: \(Int(serviceCharge)) VND per rental"
    }
    override func calculateRentalCost(days: Int) -> Double {
        guard days > 0 else { return 0 }
        return getDailyRate() * Double(days) + serviceCharge
    }
}
