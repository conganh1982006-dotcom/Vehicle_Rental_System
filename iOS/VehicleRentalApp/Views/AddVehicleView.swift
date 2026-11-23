import SwiftUI

struct AddVehicleView: View {
    @EnvironmentObject private var store: RentalStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: VehicleKind = .car
    @State private var id = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var rate = ""
    @State private var extra1 = ""
    @State private var extra2 = ""
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Vehicle type", selection: $kind) {
                        ForEach(VehicleKind.allCases) { item in Text(item.rawValue).tag(item) }
                    }
                }
                Section("Identity & Price") {
                    TextField("Unique ID (e.g. CAR003)", text: $id)
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    TextField("Daily rate (VND)", text: $rate).keyboardType(.numberPad)
                }
                Section("Specific Details") {
                    switch kind {
                    case .car:
                        TextField("Seats", text: $extra1).keyboardType(.numberPad)
                        TextField("One-time service charge", text: $extra2).keyboardType(.numberPad)
                    case .motorcycle:
                        TextField("Engine capacity (cc)", text: $extra1).keyboardType(.numberPad)
                    case .electricBicycle:
                        TextField("Battery range (km)", text: $extra1).keyboardType(.numberPad)
                        TextField("One-time battery fee", text: $extra2).keyboardType(.numberPad)
                    }
                }
                Section {
                    Button("Register Vehicle") { register() }
                        .frame(maxWidth: .infinity).fontWeight(.semibold)
                }
            }
            .navigationTitle("New Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }}
            .appError($errorText)
        }
    }

    private func register() {
        do {
            guard let dailyRate = Int(rate), let value = Int(extra1) else {
                throw RentalError.invalidInput("vehicle details")
            }
            let newVehicle: Vehicle?
            switch kind {
            case .car:
                guard let fee = Int(extra2) else { throw RentalError.invalidInput("service fee") }
                newVehicle = Car(id: id, brand: brand, model: model, dailyRate: dailyRate,
                                 seatingCapacity: value, additionalServiceCharge: fee)
            case .motorcycle:
                newVehicle = Motorcycle(id: id, brand: brand, model: model,
                                        dailyRate: dailyRate, engineCapacityCC: value)
            case .electricBicycle:
                guard let fee = Int(extra2) else { throw RentalError.invalidInput("battery fee") }
                newVehicle = ElectricBicycle(id: id, brand: brand, model: model, dailyRate: dailyRate,
                                             batteryRangeKM: value, batteryServiceFee: fee)
            }
            guard let newVehicle else { throw RentalError.invalidInput("vehicle details") }
            try store.perform { try $0.addVehicle(newVehicle) }
            dismiss()
        } catch { errorText = error.localizedDescription }
    }
}
