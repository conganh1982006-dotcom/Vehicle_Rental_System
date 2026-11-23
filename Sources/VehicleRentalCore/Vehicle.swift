import Foundation

// Shared base class for all rental vehicles.
open class Vehicle: Identifiable {
    public let id: String
    public private(set) var brand: String
    public private(set) var model: String
    public private(set) var dailyRate: Int
    public private(set) var status: VehicleStatus

    open var kind: VehicleKind { fatalError("Subclass must provide a vehicle kind") }
    open var policyDescription: String { "Daily rental rate" }
    open var specification: String { "Standard vehicle" }

    public init?(
        id: String,
        brand: String,
        model: String,
        dailyRate: Int,
        status: VehicleStatus = .available
    ) {
        guard InputValidation.nonempty(id),
              InputValidation.nonempty(brand),
              InputValidation.nonempty(model),
              dailyRate > 0 else { return nil }
        self.id = InputValidation.clean(id)
        self.brand = InputValidation.clean(brand)
        self.model = InputValidation.clean(model)
        self.dailyRate = dailyRate
        self.status = status
    }

    public func updateInfo(brand: String, model: String, dailyRate: Int) throws {
        guard InputValidation.nonempty(brand),
              InputValidation.nonempty(model),
              dailyRate > 0 else { throw RentalError.invalidInput("vehicle information") }
        self.brand = InputValidation.clean(brand)
        self.model = InputValidation.clean(model)
        self.dailyRate = dailyRate
    }

    // Subclasses override this method to implement their own rental policy.
    open func calculateRentalCost(days: Int) throws -> Int {
        guard days > 0 else { throw RentalError.invalidInput("rental days") }
        return try Money.multiply(dailyRate, days)
    }

    func markRented() throws {
        guard status == .available else { throw RentalError.vehicleUnavailable }
        status = .rented
    }

    func markReturned() throws {
        guard status == .rented else { throw RentalError.vehicleNotRented }
        status = .available
    }

    func setMaintenance(_ enabled: Bool) throws {
        guard status != .rented else { throw RentalError.vehicleAlreadyRented }
        status = enabled ? .maintenance : .available
    }
}

public final class Car: Vehicle {
    public private(set) var seatingCapacity: Int
    public private(set) var additionalServiceCharge: Int

    public override var kind: VehicleKind { .car }
    public override var specification: String { "\(seatingCapacity) seats" }
    public override var policyDescription: String {
        "Daily rate × days + \(Money.display(additionalServiceCharge)) one-time service charge"
    }

    public init?(
        id: String, brand: String, model: String, dailyRate: Int,
        seatingCapacity: Int, additionalServiceCharge: Int,
        status: VehicleStatus = .available
    ) {
        guard seatingCapacity > 0, additionalServiceCharge >= 0 else { return nil }
        self.seatingCapacity = seatingCapacity
        self.additionalServiceCharge = additionalServiceCharge
        super.init(id: id, brand: brand, model: model, dailyRate: dailyRate, status: status)
    }

    public func updateCarDetails(seatingCapacity: Int, additionalServiceCharge: Int) throws {
        guard seatingCapacity > 0, additionalServiceCharge >= 0 else {
            throw RentalError.invalidInput("car specifications")
        }
        self.seatingCapacity = seatingCapacity
        self.additionalServiceCharge = additionalServiceCharge
    }

    public override func calculateRentalCost(days: Int) throws -> Int {
        let base = try super.calculateRentalCost(days: days)
        return try Money.add(base, additionalServiceCharge)
    }
}

public final class Motorcycle: Vehicle {
    public private(set) var engineCapacityCC: Int

    public var engineCategory: EngineCategory {
        if engineCapacityCC <= 125 { return .small }
        if engineCapacityCC <= 250 { return .medium }
        return .large
    }

    public override var kind: VehicleKind { .motorcycle }
    public override var specification: String { "\(engineCapacityCC) cc • \(engineCategory.rawValue)" }
    public override var policyDescription: String {
        "(Daily rate + \(Money.display(engineCategory.dailySurcharge)) engine fee/day) × days"
    }

    public init?(
        id: String, brand: String, model: String, dailyRate: Int,
        engineCapacityCC: Int, status: VehicleStatus = .available
    ) {
        guard engineCapacityCC > 0 else { return nil }
        self.engineCapacityCC = engineCapacityCC
        super.init(id: id, brand: brand, model: model, dailyRate: dailyRate, status: status)
    }

    public func updateMotorcycleDetails(engineCapacityCC: Int) throws {
        guard engineCapacityCC > 0 else { throw RentalError.invalidInput("engine capacity") }
        self.engineCapacityCC = engineCapacityCC
    }

    public override func calculateRentalCost(days: Int) throws -> Int {
        guard days > 0 else { throw RentalError.invalidInput("rental days") }
        let dailyTotal = try Money.add(dailyRate, engineCategory.dailySurcharge)
        return try Money.multiply(dailyTotal, days)
    }
}

public final class ElectricBicycle: Vehicle {
    public private(set) var batteryRangeKM: Int
    public private(set) var batteryServiceFee: Int

    public override var kind: VehicleKind { .electricBicycle }
    public override var specification: String { "Battery range: \(batteryRangeKM) km" }
    public override var policyDescription: String {
        "Daily rate × days + \(Money.display(batteryServiceFee)) battery service fee per rental"
    }

    public init?(
        id: String, brand: String, model: String, dailyRate: Int,
        batteryRangeKM: Int, batteryServiceFee: Int,
        status: VehicleStatus = .available
    ) {
        guard batteryRangeKM > 0, batteryServiceFee >= 0 else { return nil }
        self.batteryRangeKM = batteryRangeKM
        self.batteryServiceFee = batteryServiceFee
        super.init(id: id, brand: brand, model: model, dailyRate: dailyRate, status: status)
    }

    public func updateElectricBicycleDetails(batteryRangeKM: Int, batteryServiceFee: Int) throws {
        guard batteryRangeKM > 0, batteryServiceFee >= 0 else {
            throw RentalError.invalidInput("battery specifications")
        }
        self.batteryRangeKM = batteryRangeKM
        self.batteryServiceFee = batteryServiceFee
    }

    public override func calculateRentalCost(days: Int) throws -> Int {
        let base = try super.calculateRentalCost(days: days)
        return try Money.add(base, batteryServiceFee)
    }
}
