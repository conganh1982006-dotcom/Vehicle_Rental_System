import SwiftUI

struct CustomersView: View {
    @EnvironmentObject private var store: RentalStore
    @State private var showAdd = false
    @State private var searchText = ""

    private var displayed: [Customer] {
        _ = store.revision
        return store.manager.customers.filter {
            searchText.isEmpty || "\($0.id) \($0.fullName) \($0.phoneNumber)".localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.id < $1.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Registered customers") {
                    ForEach(displayed, id: \.id) { customer in
                        NavigationLink {
                            CustomerDetailView(customerID: customer.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(customer.fullName).font(.headline)
                                Text("\(customer.id) • \(customer.phoneNumber)")
                                    .foregroundStyle(.secondary).font(.caption)
                            }.padding(.vertical, 5)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Customer name, ID or phone")
            .navigationTitle("Customers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddCustomerView() }
        }
    }
}

struct AddCustomerView: View {
    @EnvironmentObject private var store: RentalStore
    @Environment(\.dismiss) private var dismiss
    @State private var id = ""
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Details") {
                    TextField("Unique customer ID", text: $id)
                    TextField("Full name", text: $name)
                    TextField("Phone number", text: $phone).keyboardType(.phonePad)
                    TextField("Email address", text: $email).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section {
                    Button("Register Customer") { add() }.frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }}
            .appError($errorText)
        }
    }

    private func add() {
        do {
            guard let customer = Customer(id: id, fullName: name, phoneNumber: phone, email: email) else {
                throw RentalError.invalidInput("customer details")
            }
            try store.perform { try $0.registerCustomer(customer) }
            dismiss()
        } catch { errorText = error.localizedDescription }
    }
}

struct CustomerDetailView: View {
    @EnvironmentObject private var store: RentalStore
    let customerID: String
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var errorText = ""

    private var customer: Customer? {
        _ = store.revision
        return store.manager.customer(id: customerID)
    }

    private var history: [RentalRecord] {
        _ = store.revision
        return store.manager.rentalHistory(customerID: customerID)
    }

    var body: some View {
        Form {
            if let customer {
                Section("Customer Profile") {
                    LabeledContent("ID", value: customer.id)
                    LabeledContent("Registered name", value: customer.fullName)
                }
                Section("Update Contact Information") {
                    TextField("Full name", text: $name)
                    TextField("Phone number", text: $phone).keyboardType(.phonePad)
                    TextField("Email address", text: $email).keyboardType(.emailAddress)
                    Button("Save Customer Details") { update() }
                }
                Section("Rental History • \(history.count)") {
                    if history.isEmpty {
                        Text("No rental history yet.").foregroundStyle(.secondary)
                    }
                    ForEach(history, id: \.id) { rental in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(rental.id) • \(rental.vehicleID)").font(.headline)
                            Text("\(rental.rentalDays) day(s) • \(Money.display(rental.totalCost))")
                            Text(rental.isActive ? "Active" : "Returned")
                                .font(.caption).foregroundStyle(rental.isActive ? .orange : .green)
                        }.padding(.vertical, 5)
                    }
                }
            }
        }
        .navigationTitle("Customer \(customerID)")
        .onAppear(perform: fill)
        .appError($errorText)
    }

    private func fill() {
        guard let customer else { return }
        name = customer.fullName
        phone = customer.phoneNumber
        email = customer.email
    }

    private func update() {
        do {
            try store.perform {
                try $0.updateCustomer(id: customerID, fullName: name,
                                      phoneNumber: phone, email: email)
            }
        } catch { errorText = error.localizedDescription }
    }
}
