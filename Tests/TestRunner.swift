import Foundation

@MainActor
func runTests() {
    var passed = 0
    func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        if condition() { passed += 1; print("PASS: \(label)") }
        else { print("FAIL: \(label)"); exit(1) }
    }

    let sample = RentalManager()
    check(sample.vehicles.count == 6, "six sample vehicles")
    check(sample.customers.count == 3, "three sample customers")
    check(sample.records.count == 1, "sample rental record")
    check(sample.vehicle(id: "MOT002")?.isAvailable() == false, "sample rental updates availability")
    check(sample.vehicles.filter { $0 is Car }.count == 2, "car inheritance")

    let manager = RentalManager(loadSampleData: false)
    let car = Car(vehicleID: "CAR101", name: "Test Car", brand: "Toyota", dailyRate: 600000,
                  seatCount: 5, serviceCharge: 100000)!
    let motorcycle = Motorcycle(vehicleID: "MOT101", name: "Test Bike", brand: "Honda", dailyRate: 200000, engineCC: 155)!
    let ebike = ElectricBicycle(vehicleID: "EB101", name: "Test EBike", brand: "Yadea", dailyRate: 150000,
                                batteryRangeKm: 70, batteryServiceFee: 20000)!
    check(abs(car.calculateRentalCost(days: 2) - 1300000) < 0.01, "car daily fee + service charge")
    check(abs(motorcycle.calculateRentalCost(days: 2) - 460000) < 0.01, "motorcycle engine category multiplier")
    check(abs(ebike.calculateRentalCost(days: 2) - 320000) < 0.01, "electric bicycle battery fee")
    check(Car(vehicleID: "", name: "A", brand: "B", dailyRate: 1, seatCount: 2, serviceCharge: 0) == nil, "invalid ID rejected")
    check(Motorcycle(vehicleID: "BAD", name: "B", brand: "X", dailyRate: -1, engineCC: 125) == nil, "negative price rejected")
    check(ElectricBicycle(vehicleID: "BAD", name: "B", brand: "X", dailyRate: 100, batteryRangeKm: 0, batteryServiceFee: 0) == nil, "invalid battery range rejected")

    do {
        try manager.addVehicle(car)
        try manager.addVehicle(motorcycle)
        try manager.addVehicle(ebike)
        let person = Customer(customerID: "C101", fullName: "Tester", phone: "0901234567", email: "test@example.com")!
        try manager.addCustomer(person)
        check(manager.availableVehicles.count == 3, "initial vehicle availability")
        do { try manager.addVehicle(car); check(false, "duplicate vehicle rejected") }
        catch { check(true, "duplicate vehicle rejected") }
        do { try manager.rentVehicle(vehicleID: "CAR101", customerID: "C101", days: 0); check(false, "invalid duration rejected") }
        catch { check(true, "invalid duration rejected") }
        let rental = try manager.rentVehicle(vehicleID: "CAR101", customerID: "C101", days: 2)
        check(rental.getTotalCost() == 1300000, "polymorphic rental cost stored")
        check(!car.isAvailable(), "rented car becomes unavailable")
        check(manager.rentals(for: "C101").count == 1, "customer rental history")
        do { try manager.rentVehicle(vehicleID: "CAR101", customerID: "C101", days: 1); check(false, "double rental prevented") }
        catch { check(true, "double rental prevented") }
        try manager.returnVehicle(recordID: rental.getRecordID())
        check(car.isAvailable() && !rental.isActive(), "vehicle return")
        do { try manager.returnVehicle(recordID: rental.getRecordID()); check(false, "double return rejected") }
        catch { check(true, "double return rejected") }
        try manager.updateVehicle(id: "CAR101", name: "Updated", brand: "Toyota", dailyRate: 700000,
                                  seatCount: 7, serviceCharge: 50000)
        check(car.getName() == "Updated" && car.getSeatCount() == 7, "vehicle editing")
        try manager.updateCustomer(id: "C101", name: "Tester 2", phone: "0987654321", email: "test2@example.com")
        check(person.getFullName() == "Tester 2", "customer editing")
    } catch {
        print("FAIL: unexpected \(error)")
        exit(1)
    }
    print("\n\(passed) CORE TESTS PASSED")
}

@main
struct TestRunner {
    @MainActor static func main() { runTests() }
}
