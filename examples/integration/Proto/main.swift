import Foundation
import Proto_person_proto

let person = RulesXcodeproj_Examples_Integration_Person.with {
    $0.name = "Firstname Lastname"
    $0.age = 30
}

let data = try! person.serializedData()
print(Array(data))
