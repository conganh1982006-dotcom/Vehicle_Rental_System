import Foundation

// A snapshot allows class inheritance to be saved without exposing mutable model data.
public struct VehicleSnapshot: Codable {
    public let kind: VehicleKind
    public let id: String
    public let brand: String
    public let model: String
    public let dailyRate: Int
    public let status: VehicleStatus
    public let seatingCapacity: Int?
    public let additionalServiceCharge: Int?
    public let engineCapacityCC: Int?
    public let batteryRangeKM: Int?
    public let batteryServiceFee: Int?

    public init(_ vehicle: Vehicle) {
        self.kind = vehicle.kind
        self.id = vehicle.id
        self.brand = vehicle.brand
        self.model = vehicle.model
        self.dailyRate = vehicle.dailyRate
        self.status = vehicle.status
        self.seatingCapacity = (vehicle as? Car)?.seatingCapacity
        self.additionalServiceCharge = (vehicle as? Car)?.additionalServiceCharge
        self.engineCapacityCC = (vehicle as? Motorcycle)?.engineCapacityCC
        self.batteryRangeKM = (vehicle as? ElectricBicycle)?.batteryRangeKM
        self.batteryServiceFee = (vehicle as? ElectricBicycle)?.batteryServiceFee
    }

    public func makeVehicle() throws -> Vehicle {
        let created: Vehicle?
        switch kind {
        case .car:
            if let seats = seatingCapacity, let fee = additionalServiceCharge {
                created = Car(id: id, brand: brand, model: model, dailyRate: dailyRate,
                              seatingCapacity: seats, additionalServiceCharge: fee, status: status)
            } else { created = nil }
        case .motorcycle:
            if let cc = engineCapacityCC {
                created = Motorcycle(id: id, brand: brand, model: model,
                                     dailyRate: dailyRate, engineCapacityCC: cc, status: status)
            } else { created = nil }
        case .electricBicycle:
            if let range = batteryRangeKM, let fee = batteryServiceFee {
                created = ElectricBicycle(id: id, brand: brand, model: model,
                                          dailyRate: dailyRate, batteryRangeKM: range,
                                          batteryServiceFee: fee, status: status)
            } else { created = nil }
        }
        guard let vehicle = created else { throw RentalError.invalidSavedData }
        return vehicle
    }
}

private struct RentalSnapshot: Codable {
    let vehicles: [VehicleSnapshot]
    let customers: [Customer]
    let records: [RentalRecord]
    let nextRentalNumber: Int
}

public final class RentalManager {
    public private(set) var vehicles: [Vehicle] = []
    public private(set) var customers: [Customer] = []
    public private(set) var records: [RentalRecord] = []
    private var nextRentalNumber: Int = 1

    public init(seedDemo: Bool = false) {
        if seedDemo { populateDemo() }
    }

    public func vehicle(id: String) -> Vehicle? {
        vehicles.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    public func customer(id: String) -> Customer? {
        customers.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    public func rental(id: String) -> RentalRecord? {
        records.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    public func availableVehicles() -> [Vehicle] {
        vehicles.filter { $0.status == .available }
    }

    public func vehicles(kind: VehicleKind?) -> [Vehicle] {
        guard let kind else { return vehicles }
        return vehicles.filter { $0.kind == kind }
    }

    public func rentalHistory(customerID: String) -> [RentalRecord] {
        records.filter { $0.customerID.caseInsensitiveCompare(customerID) == .orderedSame }
            .sorted { $0.startDate > $1.startDate }
    }

    public func activeRentals() -> [RentalRecord] {
        records.filter(\.isActive)
    }

    public func addVehicle(_ vehicle: Vehicle) throws {
        guard self.vehicle(id: vehicle.id) == nil else { throw RentalError.duplicateVehicleID }
        guard vehicle.status == .available else { throw RentalError.vehicleUnavailable }
        vehicles.append(vehicle)
    }

    public func updateVehicle(id: String, brand: String, model: String, dailyRate: Int) throws {
        guard let vehicle = vehicle(id: id) else { throw RentalError.vehicleNotFound }
        try vehicle.updateInfo(brand: brand, model: model, dailyRate: dailyRate)
    }

    public func updateCar(id: String, seats: Int, serviceCharge: Int) throws {
        guard let car = vehicle(id: id) as? Car else { throw RentalError.vehicleNotFound }
        try car.updateCarDetails(seatingCapacity: seats, additionalServiceCharge: serviceCharge)
    }

    public func updateMotorcycle(id: String, engineCC: Int) throws {
        guard let bike = vehicle(id: id) as? Motorcycle else { throw RentalError.vehicleNotFound }
        try bike.updateMotorcycleDetails(engineCapacityCC: engineCC)
    }

    public func updateElectricBicycle(id: String, batteryRangeKM: Int, batteryServiceFee: Int) throws {
        guard let bike = vehicle(id: id) as? ElectricBicycle else { throw RentalError.vehicleNotFound }
        try bike.updateElectricBicycleDetails(batteryRangeKM: batteryRangeKM, batteryServiceFee: batteryServiceFee)
    }

    public func setMaintenance(vehicleID: String, enabled: Bool) throws {
        guard let vehicle = vehicle(id: vehicleID) else { throw RentalError.vehicleNotFound }
        try vehicle.setMaintenance(enabled)
    }

    public func registerCustomer(_ customer: Customer) throws {
        guard self.customer(id: customer.id) == nil else { throw RentalError.duplicateCustomerID }
        customers.append(customer)
    }

    public func updateCustomer(id: String, fullName: String, phoneNumber: String, email: String) throws {
        guard let customer = customer(id: id) else { throw RentalError.customerNotFound }
        try customer.updateContact(fullName: fullName, phoneNumber: phoneNumber, email: email)
    }

    @discardableResult
    public func rentVehicle(
        vehicleID: String, customerID: String, days: Int, at startDate: Date = Date()
    ) throws -> RentalRecord {
        guard let vehicle = vehicle(id: vehicleID) else { throw RentalError.vehicleNotFound }
        guard let customer = customer(id: customerID) else { throw RentalError.customerNotFound }
        guard days > 0 else { throw RentalError.invalidInput("rental days") }
        guard vehicle.status == .available else { throw RentalError.vehicleUnavailable }
        guard !records.contains(where: { $0.vehicleID == vehicle.id && $0.isActive }) else {
            throw RentalError.vehicleAlreadyRented
        }
        guard let dueDate = Calendar.current.date(byAdding: .day, value: days, to: startDate),
              dueDate > startDate else { throw RentalError.invalidInput("rental dates") }
        let totalCost = try vehicle.calculateRentalCost(days: days)
        guard nextRentalNumber < Int.max else { throw RentalError.priceOverflow }
        let recordID = "R\(String(format: "%04d", nextRentalNumber))"
        guard rental(id: recordID) == nil,
              let record = RentalRecord(id: recordID, vehicleID: vehicle.id,
                                        customerID: customer.id, rentalDays: days,
                                        startDate: startDate, dueDate: dueDate,
                                        totalCost: totalCost) else {
            throw RentalError.invalidSavedData
        }

        // Commit only after all validation and cost calculations have succeeded.
        try vehicle.markRented()
        records.append(record)
        nextRentalNumber += 1
        return record
    }

    @discardableResult
    public func returnVehicle(rentalID: String, at date: Date = Date()) throws -> RentalRecord {
        guard let record = rental(id: rentalID) else { throw RentalError.rentalNotFound }
        guard record.isActive else { throw RentalError.rentalAlreadyReturned }
        guard let vehicle = vehicle(id: record.vehicleID) else { throw RentalError.vehicleNotFound }
        guard vehicle.status == .rented else { throw RentalError.vehicleNotRented }
        guard date >= record.startDate else { throw RentalError.invalidReturnDate }
        try record.finish(at: date)
        try vehicle.markReturned()
        return record
    }

    public func totalRentalRevenue() throws -> Int {
        try records.reduce(0) { try Money.add($0, $1.totalCost) }
    }

    public func exportData() throws -> Data {
        let snapshot = RentalSnapshot(
            vehicles: vehicles.map(VehicleSnapshot.init),
            customers: customers,
            records: records,
            nextRentalNumber: nextRentalNumber
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    public func importData(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot: RentalSnapshot
        do { snapshot = try decoder.decode(RentalSnapshot.self, from: data) }
        catch { throw RentalError.invalidSavedData }
        guard snapshot.nextRentalNumber > 0 else { throw RentalError.invalidSavedData }

        let loadedVehicles = try snapshot.vehicles.map { try $0.makeVehicle() }
        let loadedCustomers = snapshot.customers
        let loadedRecords = snapshot.records

        func noDuplicateIDs(_ values: [String]) -> Bool {
            Set(values.map { $0.lowercased() }).count == values.count
        }
        guard noDuplicateIDs(loadedVehicles.map(\.id)),
              noDuplicateIDs(loadedCustomers.map(\.id)),
              noDuplicateIDs(loadedRecords.map(\.id)),
              loadedCustomers.allSatisfy({
                  Customer(id: $0.id, fullName: $0.fullName,
                           phoneNumber: $0.phoneNumber, email: $0.email) != nil
              }) else { throw RentalError.invalidSavedData }

        for record in loadedRecords {
            guard let vehicle = loadedVehicles.first(where: { $0.id == record.vehicleID }),
                  loadedCustomers.contains(where: { $0.id == record.customerID }),
                  record.rentalDays > 0,
                  record.totalCost >= 0,
                  record.dueDate > record.startDate,
                  record.returnedAt == nil || record.returnedAt! >= record.startDate else {
                throw RentalError.invalidSavedData
            }
            if record.isActive && vehicle.status != .rented { throw RentalError.invalidSavedData }
        }
        for vehicle in loadedVehicles {
            let openCount = loadedRecords.filter { $0.vehicleID == vehicle.id && $0.isActive }.count
            if openCount > 1 || (vehicle.status == .rented && openCount != 1) {
                throw RentalError.invalidSavedData
            }
        }
        if loadedRecords.contains(where: { record in
            guard record.id.hasPrefix("R"), let number = Int(record.id.dropFirst()) else { return false }
            return number >= snapshot.nextRentalNumber
        }) { throw RentalError.invalidSavedData }

        // Replace the current database only if the complete snapshot is valid.
        vehicles = loadedVehicles
        customers = loadedCustomers
        records = loadedRecords
        nextRentalNumber = snapshot.nextRentalNumber
    }

    private func populateDemo() {
        let demoVehicles: [Vehicle?] = [
            Car(id: "CAR001", brand: "Toyota", model: "Vios", dailyRate: 650_000,
                seatingCapacity: 5, additionalServiceCharge: 120_000),
            Car(id: "CAR002", brand: "Honda", model: "City", dailyRate: 700_000,
                seatingCapacity: 5, additionalServiceCharge: 150_000),
            Motorcycle(id: "MOT001", brand: "Honda", model: "Wave Alpha", dailyRate: 120_000,
                       engineCapacityCC: 110),
            Motorcycle(id: "MOT002", brand: "Yamaha", model: "Exciter 155", dailyRate: 220_000,
                       engineCapacityCC: 155),
            ElectricBicycle(id: "EB001", brand: "VinFast", model: "Feliz Neo", dailyRate: 160_000,
                            batteryRangeKM: 90, batteryServiceFee: 30_000),
            ElectricBicycle(id: "EB002", brand: "Yadea", model: "Orla", dailyRate: 140_000,
                            batteryRangeKM: 75, batteryServiceFee: 20_000)
        ]
        let demoCustomers: [Customer?] = [
            Customer(id: "CUS001", fullName: "Mai Nguyen", phoneNumber: "0901234567", email: "mai@example.com"),
            Customer(id: "CUS002", fullName: "Khanh Tran", phoneNumber: "0912345678", email: "khanh@example.com"),
            Customer(id: "CUS003", fullName: "Alex Le", phoneNumber: "0923456789", email: "alex@example.com")
        ]
        vehicles = demoVehicles.compactMap { $0 }
        customers = demoCustomers.compactMap { $0 }
    }
}
