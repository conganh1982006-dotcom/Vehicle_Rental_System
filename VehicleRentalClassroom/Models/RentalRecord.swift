import Foundation

class RentalRecord: Identifiable {
    private let recordID: String
    private let vehicleID: String
    private let customerID: String
    private let rentalDays: Int
    private let totalCost: Double
    private let rentalDate: Date
    private var returnDate: Date?

    var id: String { recordID }

    init?(recordID: String, vehicleID: String, customerID: String,
          rentalDays: Int, totalCost: Double, rentalDate: Date = Date()) {
        guard !recordID.isEmpty, !vehicleID.isEmpty, !customerID.isEmpty,
              (1...30).contains(rentalDays), totalCost.isFinite, totalCost >= 0 else { return nil }
        self.recordID = recordID
        self.vehicleID = vehicleID
        self.customerID = customerID
        self.rentalDays = rentalDays
        self.totalCost = totalCost
        self.rentalDate = rentalDate
    }

    func getRecordID() -> String { recordID }
    func getVehicleID() -> String { vehicleID }
    func getCustomerID() -> String { customerID }
    func getRentalDays() -> Int { rentalDays }
    func getTotalCost() -> Double { totalCost }
    func getRentalDate() -> Date { rentalDate }
    func getReturnDate() -> Date? { returnDate }
    func isActive() -> Bool { returnDate == nil }

    func markReturned(on date: Date = Date()) -> Bool {
        guard returnDate == nil, date >= rentalDate else { return false }
        returnDate = date
        return true
    }
}
