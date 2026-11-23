import SwiftUI

struct CustomersView: View {
    @EnvironmentObject private var manager: RentalManager
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.customers) { customer in
                    NavigationLink {
                        CustomerDetailView(customerID: customer.getCustomerID())
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.getFullName()).font(.headline)
                            Text("\(customer.getCustomerID()) · \(customer.getPhone())")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Customers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { CustomerFormView(customerID: nil) }
        }
    }
}

struct CustomerDetailView: View {
    @EnvironmentObject private var manager: RentalManager
    let customerID: String
    @State private var showEdit = false

    var body: some View {
        Group {
            if let customer = manager.customer(id: customerID) {
                List {
                    Section("Customer Information") {
                        LabeledContent("ID", value: customer.getCustomerID())
                        LabeledContent("Name", value: customer.getFullName())
                        LabeledContent("Phone", value: customer.getPhone())
                        LabeledContent("Email", value: customer.getEmail())
                        Button("Edit Contact") { showEdit = true }
                    }
                    Section("Rental History") {
                        let history = manager.rentals(for: customerID)
                        if history.isEmpty {
                            Text("No rentals yet").foregroundStyle(.secondary)
                        }
                        ForEach(history) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(manager.vehicle(id: record.getVehicleID())?.getName() ?? record.getVehicleID())
                                    .font(.headline)
                                Text("\(record.getRentalDays()) days · \(formatVND(record.getTotalCost()))")
                                    .font(.subheadline)
                                Text(record.isActive() ? "Currently rented" : "Returned")
                                    .font(.caption)
                                    .foregroundStyle(record.isActive() ? .orange : .green)
                            }
                        }
                    }
                }
                .navigationTitle(customer.getFullName())
                .sheet(isPresented: $showEdit) { CustomerFormView(customerID: customerID) }
            } else {
                Text("Customer not found")
            }
        }
    }
}

struct CustomerFormView: View {
    @EnvironmentObject private var manager: RentalManager
    @Environment(\.dismiss) private var dismiss
    let customerID: String?

    @State private var enteredID = ""
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Details") {
                    if customerID == nil {
                        TextField("Customer ID (e.g. C004)", text: $enteredID)
                    } else {
                        LabeledContent("Customer ID", value: customerID ?? "")
                    }
                    TextField("Full name", text: $name)
                    TextField("Phone (digits only)", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(customerID == nil ? "Add Customer" : "Edit Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                guard let id = customerID, let customer = manager.customer(id: id) else { return }
                enteredID = id
                name = customer.getFullName()
                phone = customer.getPhone()
                email = customer.getEmail()
            }
            .alert("Cannot Save Customer", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }

    private func save() {
        do {
            if let id = customerID {
                try manager.updateCustomer(id: id, name: name, phone: phone, email: email)
            } else {
                guard let newCustomer = Customer(customerID: enteredID,
                                                 fullName: name, phone: phone, email: email) else {
                    throw RentalError.invalidCustomer
                }
                try manager.addCustomer(newCustomer)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
