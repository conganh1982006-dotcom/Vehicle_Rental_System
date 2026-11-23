import Foundation

public final class RentalRecord: Identifiable, Codable {
    public let id: String
    public let vehicleID: String
    public let customerID: String
    public let rentalDays: Int
    public let startDate: Date
    public let dueDate: Date
    public let totalCost: Int
    public private(set) var returnedAt: Date?

    public var isActive: Bool { returnedAt == nil }

    public init?(
        id: String, vehicleID: String, customerID: String,
        rentalDays: Int, startDate: Date, dueDate: Date, totalCost: Int,
        returnedAt: Date? = nil
    ) {
        guard InputValidation.nonempty(id),
              InputValidation.nonempty(vehicleID),
              InputValidation.nonempty(customerID),
              rentalDays > 0, dueDate > startDate, totalCost >= 0,
              returnedAt == nil || returnedAt! >= startDate else { return nil }
        self.id = id
        self.vehicleID = vehicleID
        self.customerID = customerID
        self.rentalDays = rentalDays
        self.startDate = startDate
        self.dueDate = dueDate
        self.totalCost = totalCost
        self.returnedAt = returnedAt
    }

    func finish(at date: Date) throws {
        guard isActive else { throw RentalError.rentalAlreadyReturned }
        guard date >= startDate else { throw RentalError.invalidReturnDate }
        returnedAt = date
    }
}
