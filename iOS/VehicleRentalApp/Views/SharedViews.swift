import SwiftUI

struct VehicleLine: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.brand) \(vehicle.model)").font(.headline)
                Text("\(vehicle.id) • \(vehicle.kind.rawValue) • \(vehicle.specification)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(Money.display(vehicle.dailyRate)) / day").font(.subheadline)
            }
            Spacer()
            Text(vehicle.status.rawValue)
                .font(.caption.bold())
                .foregroundStyle(vehicle.status == .available ? .green : .orange)
        }
        .padding(.vertical, 5)
    }

    private var symbol: String {
        switch vehicle.kind {
        case .car: return "car.side"
        case .motorcycle: return "motorcycle"
        case .electricBicycle: return "bicycle"
        }
    }
}

struct AppErrorAlert: ViewModifier {
    @Binding var errorText: String
    func body(content: Content) -> some View {
        content.alert("Operation failed", isPresented: Binding(
            get: { !errorText.isEmpty },
            set: { if !$0 { errorText = "" } }
        )) {
            Button("OK", role: .cancel) { errorText = "" }
        } message: {
            Text(errorText)
        }
    }
}

extension View {
    func appError(_ text: Binding<String>) -> some View {
        modifier(AppErrorAlert(errorText: text))
    }
}
