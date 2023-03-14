import Foundation

struct ThreadSanitizerExamples {
    func run() {
        example1()
    }

    private func example1() {
        var name = ""
        DispatchQueue.global().async {
            name.append("Thread Sanitizer Test")
        }
        _ = name
    }
}
