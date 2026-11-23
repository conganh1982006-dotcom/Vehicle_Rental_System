import Foundation
#if canImport(Combine)
import Combine
#endif

// Business errors are displayed as alerts in SwiftUI.
enum RentalError: Error, LocalizedError {
    case invalidVehicle, duplicateVehicle, vehicleNotFound
    case invalidCustomer, duplicateCustomer, customerNotFound
    case invalidDays, vehicleUnavailable, invalidRecord, alreadyReturned

    var errorDescription: String? {
        switch self {
        case .invalidVehicle: return "Invalid vehicle information. Check the price and specifications."
        case .duplicateVehicle: return "This vehicle ID is already registered."
        case .vehicleNotFound: return "Vehicle not found."
        case .invalidCustomer: return "Invalid customer information."
        case .duplicateCustomer: return "This customer ID is already registered."
        case .customerNotFound: return "Customer not found."
        case .invalidDays: return "Rental duration must be from 1 to 30 days."
        case .vehicleUnavailable: return "This vehicle is currently rented."
        case .invalidRecord: return "Rental record not found."
        case .alreadyReturned: return "This rental has already been returned."
        }
    }
}

@MainActor
final class RentalManager: ObservableObject {
    @Published private(set) var vehicles: [Vehicle] = []
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var records: [RentalRecord] = []

    init(loadSampleData: Bool = true) {
        if loadSampleData { addSampleData() }
    }

    // MARK: - Vehicle Management

    func vehicle(id: String) -> Vehicle? {
        vehicles.first { $0.getVehicleID().caseInsensitiveCompare(id) == .orderedSame }
    }

    func addVehicle(_ newVehicle: Vehicle) throws {
        guard vehicle(id: newVehicle.getVehicleID()) == nil else {
            throw RentalError.duplicateVehicle
        }
        vehicles.append(newVehicle)
    }

    func updateVehicle(id: String, name: String, brand: String, dailyRate: Double,
                       seatCount: Int? = nil, serviceCharge: Double? = nil,
                       engineCC: Int? = nil, batteryRangeKm: Double? = nil,
                       batteryServiceFee: Double? = nil) throws {
        guard let selected = vehicle(id: id) else { throw RentalError.vehicleNotFound }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              dailyRate.isFinite, dailyRate > 0 else { throw RentalError.invalidVehicle }

        // Validate all fields before changing any values.
        if selected is Car {
            guard let seats = seatCount, let charge = serviceCharge,
                  seats > 0, charge.isFinite, charge >= 0 else { throw RentalError.invalidVehicle }
        } else if selected is Motorcycle {
            guard let cc = engineCC, cc > 0 else { throw RentalError.invalidVehicle }
        } else if selected is ElectricBicycle {
            guard let range = batteryRangeKm, let charge = batteryServiceFee,
                  range.isFinite, range > 0, charge.isFinite, charge >= 0 else {
                throw RentalError.invalidVehicle
            }
        }

        objectWillChange.send()
        _ = selected.updateCommonInfo(name: name, brand: brand, dailyRate: dailyRate)
        if let car = selected as? Car, let seats = seatCount, let charge = serviceCharge {
            _ = car.updateCarInfo(seatCount: seats, serviceCharge: charge)
        } else if let bike = selected as? Motorcycle, let cc = engineCC {
            _ = bike.updateEngineCC(cc)
        } else if let electric = selected as? ElectricBicycle,
                  let range = batteryRangeKm, let charge = batteryServiceFee {
            _ = electric.updateBatteryInfo(rangeKm: range, serviceFee: charge)
        }
    }

    var availableVehicles: [Vehicle] { vehicles.filter { $0.isAvailable() } }

    // MARK: - Customer Management

    func customer(id: String) -> Customer? {
        customers.first { $0.getCustomerID().caseInsensitiveCompare(id) == .orderedSame }
    }

    func addCustomer(_ newCustomer: Customer) throws {
        guard customer(id: newCustomer.getCustomerID()) == nil else {
            throw RentalError.duplicateCustomer
        }
        customers.append(newCustomer)
    }

    func updateCustomer(id: String, name: String, phone: String, email: String) throws {
        guard let selected = customer(id: id) else { throw RentalError.customerNotFound }
        guard Customer.validContact(name: name, phone: phone, email: email) else {
            throw RentalError.invalidCustomer
        }
        objectWillChange.send()
        _ = selected.updateContact(name: name, phone: phone, email: email)
    }

    // MARK: - Rental Management

    func rentals(for customerID: String) -> [RentalRecord] {
        records.filter { $0.getCustomerID() == customerID }
    }

    func record(id: String) -> RentalRecord? {
        records.first { $0.getRecordID() == id }
    }

    func calculateCost(vehicleID: String, days: Int) -> Double? {
        guard (1...30).contains(days), let selected = vehicle(id: vehicleID) else { return nil }
        return selected.calculateRentalCost(days: days)
    }

    @discardableResult
    func rentVehicle(vehicleID: String, customerID: String, days: Int) throws -> RentalRecord {
        guard (1...30).contains(days) else { throw RentalError.invalidDays }
        guard let selected = vehicle(id: vehicleID) else { throw RentalError.vehicleNotFound }
        guard customer(id: customerID) != nil else { throw RentalError.customerNotFound }
        guard selected.isAvailable() else { throw RentalError.vehicleUnavailable }

        let price = selected.calculateRentalCost(days: days) // Runtime polymorphism
        guard price.isFinite, price >= 0 else { throw RentalError.invalidVehicle }
        let newID = String(format: "R%03d", records.count + 1)
        guard let newRecord = RentalRecord(recordID: newID,
                                           vehicleID: selected.getVehicleID(),
                                           customerID: customerID,
                                           rentalDays: days, totalCost: price) else {
            throw RentalError.invalidRecord
        }

        // A valid rental changes availability and creates exactly one record.
        objectWillChange.send()
        guard selected.markRented() else { throw RentalError.vehicleUnavailable }
        records.append(newRecord)
        return newRecord
    }

    func returnVehicle(recordID: String) throws {
        guard let rental = record(id: recordID) else { throw RentalError.invalidRecord }
        guard rental.isActive() else { throw RentalError.alreadyReturned }
        guard let selected = vehicle(id: rental.getVehicleID()) else {
            throw RentalError.vehicleNotFound
        }
        guard !selected.isAvailable() else { throw RentalError.invalidRecord }

        objectWillChange.send()
        _ = rental.markReturned()
        _ = selected.markReturned()
    }

    // MARK: - Sample Data

    private func addSampleData() {
        let samples: [Vehicle?] = [
            Car(vehicleID: "CAR001", name: "Toyota Vios", brand: "Toyota",
                dailyRate: 600000, seatCount: 5, serviceCharge: 100000),
            Car(vehicleID: "CAR002", name: "Honda City", brand: "Honda",
                dailyRate: 650000, seatCount: 5, serviceCharge: 120000),
            Motorcycle(vehicleID: "MOT001", name: "Honda Wave", brand: "Honda",
                       dailyRate: 120000, engineCC: 110),
            Motorcycle(vehicleID: "MOT002", name: "Yamaha R15", brand: "Yamaha",
                       dailyRate: 230000, engineCC: 155),
            ElectricBicycle(vehicleID: "EB001", name: "VinFast Evo", brand: "VinFast",
                            dailyRate: 160000, batteryRangeKm: 100, batteryServiceFee: 30000),
            ElectricBicycle(vehicleID: "EB002", name: "Yadea Oris", brand: "Yadea",
                            dailyRate: 140000, batteryRangeKm: 80, batteryServiceFee: 20000)
        ]
        vehicles = samples.compactMap { $0 }
        customers = [
            Customer(customerID: "C001", fullName: "May", phone: "0901234567", email: "may@example.com"),
            Customer(customerID: "C002", fullName: "Kyo", phone: "0912345678", email: "kyo@example.com"),
            Customer(customerID: "C003", fullName: "Alex", phone: "0987654321", email: "alex@example.com")
        ].compactMap { $0 }
        _ = try? rentVehicle(vehicleID: "MOT002", customerID: "C001", days: 2)
    }
}
