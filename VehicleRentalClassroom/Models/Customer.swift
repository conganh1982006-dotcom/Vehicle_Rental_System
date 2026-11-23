import Foundation

class Customer: Identifiable {
    private let customerID: String
    private var fullName: String
    private var phone: String
    private var email: String

    var id: String { customerID }

    init?(customerID: String, fullName: String, phone: String, email: String) {
        guard Customer.validContact(name: fullName, phone: phone, email: email),
              !customerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        self.customerID = customerID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validContact(name: String, phone: String, email: String) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanName.isEmpty && (9...15).contains(cleanPhone.count)
            && cleanPhone.allSatisfy { $0.isNumber }
            && cleanEmail.contains("@") && !cleanEmail.contains(" ")
    }

    func getCustomerID() -> String { customerID }
    func getFullName() -> String { fullName }
    func getPhone() -> String { phone }
    func getEmail() -> String { email }

    func updateContact(name: String, phone: String, email: String) -> Bool {
        guard Customer.validContact(name: name, phone: phone, email: email) else { return false }
        fullName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
}
