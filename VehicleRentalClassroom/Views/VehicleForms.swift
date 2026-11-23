import SwiftUI

private enum NewVehicleType: String, CaseIterable, Identifiable {
    case car = "Car"
    case motorcycle = "Motorcycle"
    case electricBicycle = "Electric Bicycle"
    var id: String { rawValue }
}

struct AddVehicleView: View {
    @EnvironmentObject private var manager: RentalManager
    @Environment(\.dismiss) private var dismiss

    @State private var type: NewVehicleType = .car
    @State private var vehicleID = ""
    @State private var name = ""
    @State private var brand = ""
    @State private var dailyRate = ""
    @State private var seatCount = "5"
    @State private var serviceCharge = "100000"
    @State private var engineCC = "125"
    @State private var batteryRangeKm = "80"
    @State private var batteryServiceFee = "20000"
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General Information") {
                    Picker("Vehicle Type", selection: $type) {
                        ForEach(NewVehicleType.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    TextField("Vehicle ID (e.g. CAR003)", text: $vehicleID)
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Daily rate (VND)", text: $dailyRate)
                        .keyboardType(.decimalPad)
                }
                Section("Specific Information") {
                    switch type {
                    case .car:
                        TextField("Number of seats", text: $seatCount)
                            .keyboardType(.numberPad)
                        TextField("Service charge (VND)", text: $serviceCharge)
                            .keyboardType(.decimalPad)
                    case .motorcycle:
                        TextField("Engine capacity (cc)", text: $engineCC)
                            .keyboardType(.numberPad)
                    case .electricBicycle:
                        TextField("Battery range (km)", text: $batteryRangeKm)
                            .keyboardType(.decimalPad)
                        TextField("Battery service fee (VND)", text: $batteryServiceFee)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveVehicle() }
                }
            }
            .alert("Cannot Save Vehicle", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func saveVehicle() {
        guard let rate = Double(dailyRate.replacingOccurrences(of: ",", with: ".")) else {
            show("Enter a valid daily rate.")
            return
        }
        let newVehicle: Vehicle?
        switch type {
        case .car:
            newVehicle = Car(vehicleID: vehicleID, name: name, brand: brand,
                             dailyRate: rate, seatCount: Int(seatCount) ?? 0,
                             serviceCharge: Double(serviceCharge) ?? -1)
        case .motorcycle:
            newVehicle = Motorcycle(vehicleID: vehicleID, name: name, brand: brand,
                                    dailyRate: rate, engineCC: Int(engineCC) ?? 0)
        case .electricBicycle:
            newVehicle = ElectricBicycle(vehicleID: vehicleID, name: name, brand: brand,
                                         dailyRate: rate,
                                         batteryRangeKm: Double(batteryRangeKm) ?? 0,
                                         batteryServiceFee: Double(batteryServiceFee) ?? -1)
        }
        guard let newVehicle else {
            show("Please check all fields. Prices and specifications must be valid.")
            return
        }
        do {
            try manager.addVehicle(newVehicle)
            dismiss()
        } catch {
            show(error.localizedDescription)
        }
    }

    private func show(_ message: String) {
        errorMessage = message
        showError = true
    }
}

struct EditVehicleView: View {
    @EnvironmentObject private var manager: RentalManager
    @Environment(\.dismiss) private var dismiss
    let vehicleID: String

    @State private var name = ""
    @State private var brand = ""
    @State private var dailyRate = ""
    @State private var seatCount = ""
    @State private var serviceCharge = ""
    @State private var engineCC = ""
    @State private var batteryRangeKm = ""
    @State private var batteryServiceFee = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General Information") {
                    LabeledContent("Vehicle ID", value: vehicleID)
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Daily rate", text: $dailyRate).keyboardType(.decimalPad)
                }
                if let vehicle = manager.vehicle(id: vehicleID) {
                    Section("Specific Information") {
                        if vehicle is Car {
                            TextField("Seats", text: $seatCount).keyboardType(.numberPad)
                            TextField("Service charge", text: $serviceCharge).keyboardType(.decimalPad)
                        } else if vehicle is Motorcycle {
                            TextField("Engine cc", text: $engineCC).keyboardType(.numberPad)
                        } else if vehicle is ElectricBicycle {
                            TextField("Battery range (km)", text: $batteryRangeKm).keyboardType(.decimalPad)
                            TextField("Battery fee", text: $batteryServiceFee).keyboardType(.decimalPad)
                        }
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { saveChanges() } }
            }
            .onAppear(perform: loadCurrentValues)
            .alert("Cannot Update Vehicle", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func loadCurrentValues() {
        guard let vehicle = manager.vehicle(id: vehicleID) else { return }
        name = vehicle.getName()
        brand = vehicle.getBrand()
        dailyRate = String(vehicle.getDailyRate())
        if let car = vehicle as? Car {
            seatCount = String(car.getSeatCount())
            serviceCharge = String(car.getServiceCharge())
        } else if let bike = vehicle as? Motorcycle {
            engineCC = String(bike.getEngineCC())
        } else if let electric = vehicle as? ElectricBicycle {
            batteryRangeKm = String(electric.getBatteryRangeKm())
            batteryServiceFee = String(electric.getBatteryServiceFee())
        }
    }

    private func saveChanges() {
        do {
            try manager.updateVehicle(
                id: vehicleID, name: name, brand: brand,
                dailyRate: Double(dailyRate) ?? -1,
                seatCount: Int(seatCount), serviceCharge: Double(serviceCharge),
                engineCC: Int(engineCC), batteryRangeKm: Double(batteryRangeKm),
                batteryServiceFee: Double(batteryServiceFee)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
