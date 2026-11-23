import SwiftUI

private enum VehicleFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case car = "Car"
    case motorcycle = "Motorcycle"
    case electricBicycle = "Electric Bicycle"
    var id: String { rawValue }
}

struct VehiclesView: View {
    @EnvironmentObject private var manager: RentalManager
    @State private var filter: VehicleFilter = .all
    @State private var showAdd = false

    private var shownVehicles: [Vehicle] {
        manager.vehicles.filter { filter == .all || $0.getTypeName() == filter.rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Type", selection: $filter) {
                        ForEach(VehicleFilter.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }

                Section("Vehicles (\(shownVehicles.count))") {
                    ForEach(shownVehicles) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicleID: vehicle.getVehicleID())
                        } label: {
                            HStack {
                                Image(systemName: iconName(for: vehicle))
                                    .frame(width: 28)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vehicle.getName()).font(.headline)
                                    Text("\(vehicle.getVehicleID()) · \(vehicle.getTypeName())")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(vehicle.isAvailable() ? "Available" : "Rented")
                                    .font(.caption)
                                    .foregroundStyle(vehicle.isAvailable() ? .green : .orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddVehicleView() }
        }
    }
}

func iconName(for vehicle: Vehicle) -> String {
    if vehicle is Car { return "car.fill" }
    if vehicle is Motorcycle { return "motorcycle.fill" }
    return "bicycle"
}

struct VehicleDetailView: View {
    @EnvironmentObject private var manager: RentalManager
    let vehicleID: String
    @State private var showEdit = false
    @State private var showRent = false

    var body: some View {
        Group {
            if let vehicle = manager.vehicle(id: vehicleID) {
                Form {
                    Section("Vehicle Information") {
                        LabeledContent("Vehicle ID", value: vehicle.getVehicleID())
                        LabeledContent("Name", value: vehicle.getName())
                        LabeledContent("Brand", value: vehicle.getBrand())
                        LabeledContent("Type", value: vehicle.getTypeName())
                        LabeledContent("Daily rate", value: formatVND(vehicle.getDailyRate()))
                        LabeledContent("Status", value: vehicle.isAvailable() ? "Available" : "Rented")
                    }
                    Section("Specific Information") {
                        Text(vehicle.getSpecifications())
                    }
                    Section {
                        Button("Rent This Vehicle") { showRent = true }
                            .disabled(!vehicle.isAvailable())
                        Button("Edit Vehicle") { showEdit = true }
                    }
                }
                .navigationTitle(vehicle.getName())
                .sheet(isPresented: $showEdit) { EditVehicleView(vehicleID: vehicleID) }
                .sheet(isPresented: $showRent) { RentVehicleView(preselectedVehicleID: vehicleID) }
            } else {
                Text("Vehicle not found")
            }
        }
    }
}
