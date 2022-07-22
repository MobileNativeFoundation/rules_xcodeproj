// extension Dictionary where Key == BazelLabel, Value == TargetID {
//     func targetID(
//         for label: BazelLabel,
//         context: @autoclosure () -> String = ""
//     ) throws -> TargetID {
//         guard let targetID = self[label] else {
//             let contextStr = context()
//             let endOfMsg = contextStr.isEmpty ? "" : " while \(contextStr)"
//             throw PreconditionError(message: """
// Unable to find the `TargetID` for the BazelLabel "\(label)"\(endOfMsg).
// """)
//         }
//         return targetID
//     }
// }

extension Dictionary {
    func value(
        for key: Key,
        context: @autoclosure () -> String = ""
    ) throws -> Value {
        guard let value = self[key] else {
            let contextStr = context()
            let endOfMsg = contextStr.isEmpty ? "" : " while \(contextStr)"
            throw PreconditionError(message: """
Unable to find the `\(Value.self)` for the `\(Key.self)` "\(key)"\(endOfMsg).
""")
        }
        return value
    }
    // func value<K, V>(
    //     for key: K,
    //     context: @autoclosure () -> String = ""
    // ) throws -> V where K == Key, V == Value {
    //     guard let value = self[key] else {
    //         let contextStr = context()
    //         let endOfMsg = contextStr.isEmpty ? "" : " while \(contextStr)"
    //         throw PreconditionError(message: """
// Unable to find the `\(V.Type)` for the `\(K.Type)` "\(key)"\(endOfMsg).
// """)
    //     }
    //     return value
    // }
}
