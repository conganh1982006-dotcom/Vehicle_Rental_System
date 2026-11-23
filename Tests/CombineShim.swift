// A tiny test-only stand-in for Combine, used when running core logic on Linux.
#if !canImport(Combine)
struct MockPublisher {
    func send() { }
}
protocol ObservableObject: AnyObject { }
extension ObservableObject {
    var objectWillChange: MockPublisher { MockPublisher() }
}
@propertyWrapper
struct Published<Value> {
    var wrappedValue: Value
    init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
}
#endif
