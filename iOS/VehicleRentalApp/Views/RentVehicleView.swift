import SwiftUI

struct RentVehicleView: View {
    @EnvironmentObject private var store: RentalStore
    @Environment(\.dismiss) private var dismiss
    let vehicleID: String
    @State private var selectedCustomer = ""
    @State private var days = 1
    @State private var errorText = ""

    private var vehicle: Vehicle? {
        _ = store.revision
        return store.manager.vehicle(id: vehicleID)
    }

    private var estimatedCost: String {
        guard let vehicle, let total = try? vehicle.calculateRentalCost(days: days) else { return "Invalid price" }
        return Money.display(total)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let vehicle {
                    Section("Selected Vehicle") {
                        LabeledContent("Vehicle", value: "\(vehicle.brand) \(vehicle.model)")
                        LabeledContent("ID", value: vehicleID)
                        Text(vehicle.policyDescription).font(.caption).foregroundStyle(.secondary)
                    }
                    Section("Rental Details") {
                        Picker("Customer", selection: $selectedCustomer) {
                            Text("Select a customer").tag("")
                            ForEach(store.manager.customers, id: \.id) { customer in
                                Text("\(customer.fullName) (\(customer.id))").tag(customer.id)
                            }
                        }
                        Stepper("Days: \(days)", value: $days, in: 1...365)
                        LabeledContent("Total cost", value: estimatedCost)
                    }
                    Section {
                        Button("Confirm Rental") { rent() }
                            .disabled(selectedCustomer.isEmpty || vehicle.status != .available)
                            .frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Rent Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }}
            .appError($errorText)
        }
    }

    private func rent() {
        do {
            try store.perform { manager in
                try manager.rentVehicle(vehicleID: vehicleID,
                                        customerID: selectedCustomer, days: days)
            }
            dismiss()
        } catch { errorText = error.localizedDescription }
    }
}
