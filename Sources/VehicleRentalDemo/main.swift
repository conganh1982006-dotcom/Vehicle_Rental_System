import Foundation
import VehicleRentalCore

func printVehicles(_ manager: RentalManager) {
    print("\n--- VEHICLES ---")
    for vehicle in manager.vehicles {
        print("\(vehicle.id) | \(vehicle.kind.rawValue) | \(vehicle.brand) \(vehicle.model) | \(vehicle.specification) | \(Money.display(vehicle.dailyRate))/day | \(vehicle.status.rawValue)")
    }
}

func printCustomers(_ manager: RentalManager) {
    print("\n--- CUSTOMERS ---")
    for customer in manager.customers {
        print("\(customer.id) | \(customer.fullName) | \(customer.phoneNumber) | \(customer.email)")
    }
}

func printRentals(_ manager: RentalManager) {
    print("\n--- RENTALS ---")
    for record in manager.records {
        print("\(record.id) | \(record.vehicleID) | \(record.customerID) | \(record.rentalDays) day(s) | \(Money.display(record.totalCost)) | \(record.isActive ? "Active" : "Returned")")
    }
}

func input(_ prompt: String) -> String {
    print(prompt, terminator: ": ")
    return readLine() ?? ""
}

func inputInt(_ prompt: String) -> Int? { Int(input(prompt)) }

func runDemo(_ manager: RentalManager) {
    print("===== VEHICLE RENTAL OOP DEMONSTRATION =====")
    printVehicles(manager)
    printCustomers(manager)
    print("\n--- POLYMORPHIC PRICING FOR 3 DAYS ---")
    for vehicle in manager.vehicles {
        if let price = try? vehicle.calculateRentalCost(days: 3) {
            print("\(vehicle.id): \(Money.display(price)) | \(vehicle.policyDescription)")
        }
    }
    do {
        let record = try manager.rentVehicle(vehicleID: "CAR001", customerID: "CUS001", days: 3)
        print("\nRented \(record.vehicleID): \(record.id) | Total \(Money.display(record.totalCost))")
        do {
            _ = try manager.rentVehicle(vehicleID: "CAR001", customerID: "CUS002", days: 1)
        } catch { print("Expected rejection (already rented): \(error.localizedDescription)") }
        try manager.returnVehicle(rentalID: record.id)
        print("Returned \(record.vehicleID), now \(manager.vehicle(id: record.vehicleID)?.status.rawValue ?? "unknown")")
        do {
            try manager.returnVehicle(rentalID: record.id)
        } catch { print("Expected rejection (double return): \(error.localizedDescription)") }
        do {
            _ = try manager.rentVehicle(vehicleID: "MOT001", customerID: "CUS001", days: 0)
        } catch { print("Expected rejection (invalid days): \(error.localizedDescription)") }
    } catch { print("Unexpected demo failure: \(error.localizedDescription)") }
    printRentals(manager)
    print("===== END OF DEMO =====")
}

func interactiveMenu(_ manager: RentalManager) {
    while true {
        print("\n===== VEHICLE RENTAL MENU =====")
        print("1 Vehicles  2 Add vehicle  3 Update vehicle  4 Maintenance")
        print("5 Customers  6 Register customer  7 Update customer")
        print("8 Rent  9 Return  10 Rentals  11 Customer history  12 Revenue  0 Exit")
        let choice = input("Choose")
        do {
            switch choice {
            case "1": printVehicles(manager)
            case "2":
                let kind = input("Type (car/motorcycle/electric)").lowercased()
                let id = input("Vehicle ID")
                let brand = input("Brand")
                let model = input("Model")
                guard let rate = inputInt("Daily rate (VND)") else { throw RentalError.invalidInput("daily rate") }
                let vehicle: Vehicle?
                switch kind {
                case "car":
                    guard let seats = inputInt("Seats"), let fee = inputInt("One-time service charge") else { throw RentalError.invalidInput("car details") }
                    vehicle = Car(id: id, brand: brand, model: model, dailyRate: rate, seatingCapacity: seats, additionalServiceCharge: fee)
                case "motorcycle":
                    guard let cc = inputInt("Engine capacity (cc)") else { throw RentalError.invalidInput("engine capacity") }
                    vehicle = Motorcycle(id: id, brand: brand, model: model, dailyRate: rate, engineCapacityCC: cc)
                case "electric":
                    guard let range = inputInt("Battery range (km)"), let fee = inputInt("Battery service fee") else { throw RentalError.invalidInput("battery details") }
                    vehicle = ElectricBicycle(id: id, brand: brand, model: model, dailyRate: rate, batteryRangeKM: range, batteryServiceFee: fee)
                default: throw RentalError.invalidInput("vehicle type")
                }
                guard let vehicle else { throw RentalError.invalidInput("vehicle details") }
                try manager.addVehicle(vehicle)
                print("Vehicle registered.")
            case "3":
                let id = input("Vehicle ID")
                let brand = input("New brand")
                let model = input("New model")
                guard let rate = inputInt("New daily rate") else { throw RentalError.invalidInput("daily rate") }
                try manager.updateVehicle(id: id, brand: brand, model: model, dailyRate: rate)
                if let car = manager.vehicle(id: id) as? Car {
                    print("Car-specific fields: \(car.specification). Update separately in the SwiftUI detail view.")
                }
                print("Vehicle updated.")
            case "4":
                let id = input("Vehicle ID")
                try manager.setMaintenance(vehicleID: id, enabled: input("Enable maintenance? (y/n)").lowercased() == "y")
                print("Maintenance status updated.")
            case "5": printCustomers(manager)
            case "6":
                guard let customer = Customer(id: input("Customer ID"), fullName: input("Full name"), phoneNumber: input("Phone"), email: input("Email")) else {
                    throw RentalError.invalidInput("customer details")
                }
                try manager.registerCustomer(customer)
                print("Customer registered.")
            case "7":
                let id = input("Customer ID")
                try manager.updateCustomer(id: id, fullName: input("New name"), phoneNumber: input("New phone"), email: input("New email"))
                print("Customer updated.")
            case "8":
                let vehicleID = input("Vehicle ID")
                let customerID = input("Customer ID")
                guard let days = inputInt("Rental days") else { throw RentalError.invalidInput("rental days") }
                let record = try manager.rentVehicle(vehicleID: vehicleID, customerID: customerID, days: days)
                print("Rental \(record.id) created. Total: \(Money.display(record.totalCost))")
            case "9":
                try manager.returnVehicle(rentalID: input("Rental ID"))
                print("Vehicle returned.")
            case "10": printRentals(manager)
            case "11":
                let id = input("Customer ID")
                guard manager.customer(id: id) != nil else { throw RentalError.customerNotFound }
                for record in manager.rentalHistory(customerID: id) {
                    print("\(record.id) | \(record.vehicleID) | \(record.rentalDays) days | \(Money.display(record.totalCost)) | \(record.isActive ? "Active" : "Returned")")
                }
            case "12": print("Total rental costs: \(Money.display(try manager.totalRentalRevenue()))")
            case "0": return
            default: print("Unknown menu option.")
            }
        } catch { print("ERROR: \(error.localizedDescription)") }
    }
}

let manager = RentalManager(seedDemo: true)
let args = CommandLine.arguments
if args.contains("--interactive") {
    interactiveMenu(manager)
} else {
    runDemo(manager)
    print("\nTip: Run with --interactive for the complete employee menu.")
}
