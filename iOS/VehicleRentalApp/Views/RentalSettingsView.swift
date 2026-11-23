import SwiftUI

struct RentalSettingsView: View {
    @EnvironmentObject private var store: RentalStore
    @AppStorage("appearance") private var appearance = "system"
    @State private var showReset = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Data Storage") {
                    LabeledContent("Vehicles", value: String(store.manager.vehicles.count))
                    LabeledContent("Customers", value: String(store.manager.customers.count))
                    LabeledContent("Rental records", value: String(store.manager.records.count))
                    Text("Data is stored as JSON in the app's Documents directory and restored on next launch.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Demo Tools") {
                    Button("Reset to Sample Data", role: .destructive) { showReset = true }
                    Text("This removes current data and restores six vehicles and three customers.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Pricing Assumptions") {
                    Text("Car: daily rate × days + a one-time service charge.")
                    Text("Motorcycle: daily rate + category-based daily surcharge, multiplied by days.")
                    Text("Electric bicycle: daily rate × days + one-time battery service fee.")
                    Text("These fees are project assumptions because the assignment does not specify their amounts.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all rental data?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset to Demo", role: .destructive) {
                    do { try store.resetDemo() }
                    catch { errorText = error.localizedDescription }
                }
            }
            .appError($errorText)
        }
    }
}
