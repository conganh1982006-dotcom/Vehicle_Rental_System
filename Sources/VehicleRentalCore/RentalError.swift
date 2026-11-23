import Foundation

public enum RentalError: Error, LocalizedError, Equatable {
    case invalidInput(String)
    case duplicateVehicleID
    case duplicateCustomerID
    case vehicleNotFound
    case customerNotFound
    case rentalNotFound
    case vehicleUnavailable
    case vehicleAlreadyRented
    case vehicleNotRented
    case rentalAlreadyReturned
    case invalidReturnDate
    case invalidSavedData
    case priceOverflow

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let field): return "Invalid value: \(field)."
        case .duplicateVehicleID: return "A vehicle with this ID already exists."
        case .duplicateCustomerID: return "A customer with this ID already exists."
        case .vehicleNotFound: return "Vehicle not found."
        case .customerNotFound: return "Customer not found."
        case .rentalNotFound: return "Rental record not found."
        case .vehicleUnavailable: return "Vehicle is not available for rental."
        case .vehicleAlreadyRented: return "Vehicle is already rented."
        case .vehicleNotRented: return "Vehicle is not currently rented."
        case .rentalAlreadyReturned: return "This rental has already been returned."
        case .invalidReturnDate: return "Return date cannot precede the rental start."
        case .invalidSavedData: return "Saved data has invalid or conflicting records."
        case .priceOverflow: return "Rental amount is too large to calculate safely."
        }
    }
}

public enum VehicleKind: String, Codable, CaseIterable, Identifiable {
    case car = "Car"
    case motorcycle = "Motorcycle"
    case electricBicycle = "Electric Bicycle"
    public var id: String { rawValue }
}

public enum VehicleStatus: String, Codable, CaseIterable {
    case available = "Available"
    case rented = "Rented"
    case maintenance = "Maintenance"
}

public enum EngineCategory: String, CaseIterable {
    case small = "Up to 125 cc"
    case medium = "126–250 cc"
    case large = "Over 250 cc"

    public var dailySurcharge: Int {
        switch self {
        case .small: return 0
        case .medium: return 20_000
        case .large: return 40_000
        }
    }
}

public enum Money {
    public static func multiply(_ amount: Int, _ times: Int) throws -> Int {
        guard amount >= 0, times >= 0 else { throw RentalError.invalidInput("amount") }
        let (result, overflow) = amount.multipliedReportingOverflow(by: times)
        if overflow { throw RentalError.priceOverflow }
        return result
    }

    public static func add(_ first: Int, _ second: Int) throws -> Int {
        let (result, overflow) = first.addingReportingOverflow(second)
        if overflow { throw RentalError.priceOverflow }
        return result
    }

    public static func display(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        return "\(formatter.string(from: NSNumber(value: amount)) ?? String(amount)) VND"
    }
}

public enum InputValidation {
    public static func clean(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func nonempty(_ input: String) -> Bool {
        !clean(input).isEmpty
    }

    public static func phone(_ input: String) -> Bool {
        let raw = clean(input)
        let digits = raw.hasPrefix("+") ? String(raw.dropFirst()) : raw
        return (9...12).contains(digits.count) &&
            digits.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    public static func email(_ input: String) -> Bool {
        let text = clean(input)
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") &&
            !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".") && !text.contains(" ")
    }
}
