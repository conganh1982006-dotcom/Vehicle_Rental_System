import SwiftUI

// The app uses three simple tabs and one shared manager.
struct ContentView: View {
    @StateObject private var manager = RentalManager()

    var body: some View {
        TabView {
            VehiclesView()
                .tabItem { Label("Vehicles", systemImage: "car.fill") }

            CustomersView()
                .tabItem { Label("Customers", systemImage: "person.2.fill") }

            RentalsView()
                .tabItem { Label("Rentals", systemImage: "list.clipboard.fill") }
        }
        .environmentObject(manager)
    }
}

// Format amounts in Vietnamese dong throughout the application.
func formatVND(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "vi_VN")
    formatter.maximumFractionDigits = 0
    return "\(formatter.string(from: NSNumber(value: amount)) ?? "0") VND"
}
