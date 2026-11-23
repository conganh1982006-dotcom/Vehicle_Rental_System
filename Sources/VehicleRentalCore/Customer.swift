import Foundation

public final class Customer: Identifiable, Codable {
    public let id: String
    public private(set) var fullName: String
    public private(set) var phoneNumber: String
    public private(set) var email: String

    public init?(id: String, fullName: String, phoneNumber: String, email: String) {
        guard InputValidation.nonempty(id),
              InputValidation.nonempty(fullName),
              InputValidation.phone(phoneNumber),
              InputValidation.email(email) else { return nil }
        self.id = InputValidation.clean(id)
        self.fullName = InputValidation.clean(fullName)
        self.phoneNumber = InputValidation.clean(phoneNumber)
        self.email = InputValidation.clean(email)
    }

    public func updateContact(fullName: String, phoneNumber: String, email: String) throws {
        guard InputValidation.nonempty(fullName),
              InputValidation.phone(phoneNumber),
              InputValidation.email(email) else { throw RentalError.invalidInput("customer contact") }
        self.fullName = InputValidation.clean(fullName)
        self.phoneNumber = InputValidation.clean(phoneNumber)
        self.email = InputValidation.clean(email)
    }
}
