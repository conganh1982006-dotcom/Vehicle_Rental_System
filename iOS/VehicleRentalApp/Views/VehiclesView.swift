import SwiftUI

struct VehiclesView: View {
    @EnvironmentObject private var store: RentalStore
    @State private var searchText = ""
    @State private var selectedKind = "All"
    @State private var availableOnly = false
    @State private var showAdd = false

    private var filtered: [Vehicle] {
        _ = store.revision
        return store.manager.vehicles.filter { vehicle in
            (selectedKind == "All" || vehicle.kind.rawValue == selectedKind) &&
            (!availableOnly || vehicle.status == .available) &&
            (searchText.isEmpty || "\(vehicle.id) \(vehicle.brand) \(vehicle.model)".localizedCaseInsensitiveContains(searchText))
        }.sorted { $0.id < $1.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Vehicle type", selection: $selectedKind) {
                        Text("All").tag("All")
                        ForEach(VehicleKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind.rawValue)
                        }
                    }
                    Toggle("Available only", isOn: $availableOnly)
                }
                Section("Fleet • \(filtered.count) vehicles") {
                    ForEach(filtered, id: \.id) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicleID: vehicle.id)
                        } label: {
                            VehicleLine(vehicle: vehicle)
                        }
                    }
                    if filtered.isEmpty {
                        Text("No matching vehicles.").foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search ID, brand or model")
            .navigationTitle("Vehicle Fleet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddVehicleView() }
        }
    }
}

struct VehicleDetailView: View {
    @EnvironmentObject private var store: RentalStore
    let vehicleID: String
    @State private var brand = ""
    @State private var model = ""
    @State private var rate = ""
    @State private var extra1 = ""
    @State private var extra2 = ""
    @State private var showRent = false
    @State private var errorText = ""

    private var vehicle: Vehicle? {
        _ = store.revision
        return store.manager.vehicle(id: vehicleID)
    }

    var body: some View {
        Form {
            if let vehicle {
                Section("Vehicle Details") {
                    LabeledContent("ID", value: vehicle.id)
                    LabeledContent("Type", value: vehicle.kind.rawValue)
                    LabeledContent("Status", value: vehicle.status.rawValue)
                    LabeledContent("Specifications", value: vehicle.specification)
                    LabeledContent("Pricing", value: vehicle.policyDescription)
                }
                Section("Edit General Information") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    TextField("Daily rate (VND)", text: $rate).keyboardType(.numberPad)
                    Button("Save General Information") { saveGeneral() }
                }
                Section("Edit Vehicle-Specific Information") {
                    if vehicle is Car {
                        TextField("Seating capacity", text: $extra1).keyboardType(.numberPad)
                        TextField("One-time service charge", text: $extra2).keyboardType(.numberPad)
                    } else if vehicle is Motorcycle {
                        TextField("Engine capacity (cc)", text: $extra1).keyboardType(.numberPad)
                    } else if vehicle is ElectricBicycle {
                        TextField("Battery range (km)", text: $extra1).keyboardType(.numberPad)
                        TextField("Battery service fee", text: $extra2).keyboardType(.numberPad)
                    }
                    Button("Save Specifications") { saveSpecific() }
                }
                Section("Rental Actions") {
                    Button("Rent This Vehicle") { showRent = true }
                        .disabled(vehicle.status != .available)
                    if vehicle.status == .rented {
                        Text("Return this vehicle from the Rentals tab.")
                            .foregroundStyle(.secondary)
                    } else {
                        Button(vehicle.status == .maintenance ? "Finish Maintenance" : "Move to Maintenance") {
                            do {
                                try store.perform {
                                    try $0.setMaintenance(vehicleID: vehicleID, enabled: vehicle.status != .maintenance)
                                }
                            } catch { errorText = error.localizedDescription }
                        }
                    }
                }
            }
        }
        .navigationTitle("Vehicle \(vehicleID)")
        .onAppear(perform: fillFields)
        .sheet(isPresented: $showRent) { RentVehicleView(vehicleID: vehicleID) }
        .appError($errorText)
    }

    private func fillFields() {
        guard let vehicle else { return }
        brand = vehicle.brand
        model = vehicle.model
        rate = String(vehicle.dailyRate)
        if let car = vehicle as? Car {
            extra1 = String(car.seatingCapacity)
            extra2 = String(car.additionalServiceCharge)
        } else if let motorcycle = vehicle as? Motorcycle {
            extra1 = String(motorcycle.engineCapacityCC)
        } else if let bicycle = vehicle as? ElectricBicycle {
            extra1 = String(bicycle.batteryRangeKM)
            extra2 = String(bicycle.batteryServiceFee)
        }
    }

    private func saveGeneral() {
        do {
            guard let parsed = Int(rate) else { throw RentalError.invalidInput("daily rate") }
            try store.perform {
                try $0.updateVehicle(id: vehicleID, brand: brand, model: model, dailyRate: parsed)
            }
        } catch { errorText = error.localizedDescription }
    }

    private func saveSpecific() {
        do {
            guard let first = Int(extra1) else { throw RentalError.invalidInput("specifications") }
            try store.perform { manager in
                if vehicle is Car {
                    guard let second = Int(extra2) else { throw RentalError.invalidInput("service charge") }
                    try manager.updateCar(id: vehicleID, seats: first, serviceCharge: second)
                } else if vehicle is Motorcycle {
                    try manager.updateMotorcycle(id: vehicleID, engineCC: first)
                } else {
                    guard let second = Int(extra2) else { throw RentalError.invalidInput("battery fee") }
                    try manager.updateElectricBicycle(id: vehicleID, batteryRangeKM: first, batteryServiceFee: second)
                }
            }
        } catch { errorText = error.localizedDescription }
    }
}
