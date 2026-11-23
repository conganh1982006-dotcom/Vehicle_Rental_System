import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: RentalStore

    var body: some View {
        TabView {
            VehiclesView()
                .tabItem { Label("Vehicles", systemImage: "car.side.fill") }
            CustomersView()
                .tabItem { Label("Customers", systemImage: "person.2.fill") }
            RentalsView()
                .tabItem { Label("Rentals", systemImage: "calendar.badge.clock") }
            RentalSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
        .alert("Storage notice", isPresented: Binding(
            get: { store.startupMessage != nil },
            set: { if !$0 { store.dismissStartupMessage() } }
        )) {
            Button("OK") { store.dismissStartupMessage() }
        } message: {
            Text(store.startupMessage ?? "")
        }
    }
}
