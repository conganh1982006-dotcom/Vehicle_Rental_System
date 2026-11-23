import Foundation
import Combine

// The observable adapter connects the Foundation-only business layer to SwiftUI.
@MainActor
final class RentalStore: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var startupMessage: String?
    let manager: RentalManager
    let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = directory.appendingPathComponent("vehicle_rental_data.json")
        let manager = RentalManager(seedDemo: true)
        self.manager = manager
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                try manager.importData(data)
            } catch {
                startupMessage = "Saved data could not be loaded: \(error.localizedDescription). Demo data is displayed but the saved file was not overwritten."
            }
        } else {
            do { try manager.exportData().write(to: fileURL, options: .atomic) }
            catch { startupMessage = "Initial data could not be saved: \(error.localizedDescription)" }
        }
    }

    // A failed disk write restores the previous in-memory data snapshot.
    @discardableResult
    func perform<T>(_ operation: (RentalManager) throws -> T) throws -> T {
        let oldData = try manager.exportData()
        do {
            let result = try operation(manager)
            try manager.exportData().write(to: fileURL, options: .atomic)
            revision += 1
            return result
        } catch {
            try? manager.importData(oldData)
            revision += 1
            throw error
        }
    }

    func dismissStartupMessage() { startupMessage = nil }

    func resetDemo() throws {
        let restored = RentalManager(seedDemo: true)
        let newData = try restored.exportData()
        try newData.write(to: fileURL, options: .atomic)
        try manager.importData(newData)
        startupMessage = nil
        revision += 1
    }
}
