import SwiftUI

struct RentalsView: View {
    @EnvironmentObject private var store: RentalStore
    @State private var showActiveOnly = true
    @State private var selectedReturnID: String?
    @State private var errorText = ""

    private var displayed: [RentalRecord] {
        _ = store.revision
        let records = store.manager.records
        return (showActiveOnly ? records.filter(\.isActive) : records)
            .sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Active rentals only", isOn: $showActiveOnly)
                    LabeledContent("Active", value: String(store.manager.activeRentals().count))
                    LabeledContent("Total rental costs", value:
                        Money.display((try? store.manager.totalRentalRevenue()) ?? 0))
                }
                Section("Rental Records") {
                    ForEach(displayed, id: \.id) { rental in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text(rental.id).font(.headline)
                                Spacer()
                                Text(rental.isActive ? "Active" : "Returned")
                                    .foregroundStyle(rental.isActive ? .orange : .green)
                                    .font(.caption.bold())
                            }
                            if let vehicle = store.manager.vehicle(id: rental.vehicleID) {
                                Text("\(vehicle.brand) \(vehicle.model) (\(rental.vehicleID))")
                            } else {
                                Text(rental.vehicleID)
                            }
                            if let customer = store.manager.customer(id: rental.customerID) {
                                Text("Customer: \(customer.fullName)").font(.subheadline)
                            }
                            Text("\(rental.rentalDays) day(s) • \(Money.display(rental.totalCost))")
                                .font(.subheadline)
                            Text("Start: \(rental.startDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Due: \(rental.dueDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                            if let returned = rental.returnedAt {
                                Text("Returned: \(returned.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if rental.isActive {
                                Button("Return Vehicle") { selectedReturnID = rental.id }
                                    .buttonStyle(.borderedProminent)
                            }
                        }.padding(.vertical, 6)
                    }
                    if displayed.isEmpty {
                        Text("No rental records in this view.").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Rentals")
            .confirmationDialog(
                "Confirm Vehicle Return",
                isPresented: Binding(get: { selectedReturnID != nil },
                                     set: { if !$0 { selectedReturnID = nil } }),
                titleVisibility: .visible
            ) {
                Button("Confirm Return") { returnSelected() }
                Button("Cancel", role: .cancel) { selectedReturnID = nil }
            } message: { Text("This will close the rental and make its vehicle available again.") }
            .appError($errorText)
        }
    }

    private func returnSelected() {
        guard let id = selectedReturnID else { return }
        selectedReturnID = nil
        do {
            try store.perform { try $0.returnVehicle(rentalID: id) }
        } catch { errorText = error.localizedDescription }
    }
}
