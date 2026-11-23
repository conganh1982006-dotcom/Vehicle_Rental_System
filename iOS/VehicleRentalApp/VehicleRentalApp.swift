import SwiftUI

@main
struct VehicleRentalApp: App {
    @StateObject private var store = RentalStore()
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(
                    appearance == "dark" ? .dark :
                    appearance == "light" ? .light : nil
                )
        }
    }
}
