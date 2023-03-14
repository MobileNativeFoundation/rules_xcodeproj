import Foundation

struct AddressSanitizerExamples {
    func run() {
        example1()
    }

    private func example1() {
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: 1,
            alignment: 1
        )
        pointer.storeBytes(
            of: 1,
            as: UInt8.self
        )
        pointer.advanced(by: 1).storeBytes(
            of: 2,
            as: UInt8.self
        )
    }
}
