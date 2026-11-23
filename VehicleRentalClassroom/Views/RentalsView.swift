import SwiftUI

struct RentalsView: View {
    @EnvironmentObject private var manager: RentalManager
    @State private var showNewRental = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                Section("Rental Records") {
                    if manager.records.isEmpty {
                        Text("No rentals yet").foregroundStyle(.secondary)
                    }
                    ForEach(manager.records) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(record.getRecordID()).font(.headline)
                                Spacer()
                                Text(record.isActive() ? "Active" : "Returned")
                                    .font(.caption.bold())
                                    .foregroundStyle(record.isActive() ? .orange : .green)
                            }
                            Text(manager.vehicle(id: record.getVehicleID())?.getName() ?? record.getVehicleID())
                            Text("Customer: \(manager.customer(id: record.getCustomerID())?.getFullName() ?? record.getCustomerID())")
                                .font(.subheadline)
                            Text("\(record.getRentalDays()) days · \(formatVND(record.getTotalCost()))")
                                .font(.subheadline.bold())
                            if record.isActive() {
                                Button("Return Vehicle") { returnVehicle(record.getRecordID()) }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Rentals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewRental = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNewRental) { RentVehicleView() }
            .alert("Cannot Return Vehicle", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func returnVehicle(_ recordID: String) {
        do { try manager.returnVehicle(recordID: recordID) }
        catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct RentVehicleView: View {
    @EnvironmentObject private var manager: RentalManager
    @Environment(\.dismiss) private var dismiss

    @State private var vehicleID: String
    @State private var customerID = ""
    @State private var days = 1
    @State private var errorMessage = ""
    @State private var showError = false

    init(preselectedVehicleID: String? = nil) {
        _vehicleID = State(initialValue: preselectedVehicleID ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rental Details") {
                    Picker("Vehicle", selection: $vehicleID) {
                        Text("Select vehicle").tag("")
                        ForEach(manager.availableVehicles) { vehicle in
                            Text("\(vehicle.getName()) (\(vehicle.getVehicleID()))")
                                .tag(vehicle.getVehicleID())
                        }
                    }
                    Picker("Customer", selection: $customerID) {
                        Text("Select customer").tag("")
                        ForEach(manager.customers) { customer in
                            Text(customer.getFullName()).tag(customer.getCustomerID())
                        }
                    }
                    Stepper("Rental days: \(days)", value: $days, in: 1...30)
                }
                Section("Cost Preview") {
                    if let cost = manager.calculateCost(vehicleID: vehicleID, days: days) {
                        Text(formatVND(cost)).font(.title3.bold())
                    } else {
                        Text("Select a vehicle").foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Confirm Rental") { confirm() }
                        .disabled(vehicleID.isEmpty || customerID.isEmpty)
                }
            }
            .navigationTitle("Rent Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Cannot Rent Vehicle", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func confirm() {
        do {
            try manager.rentVehicle(vehicleID: vehicleID, customerID: customerID, days: days)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
