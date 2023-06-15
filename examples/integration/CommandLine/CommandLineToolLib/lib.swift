@_implementationOnly import _Lib
@_implementationOnly import _SwiftLib
import ExternalFramework
import Foundation
import ImportableLibrary
import Stringify
import SwiftCModule

@objcMembers
public class SwiftGreetings: NSObject {
    public static func greeting() -> String {
        let (answer, equation) = #stringify(1 + 2)
        return privateGreeting + String(cString: cc_greeting()) + Baz.bar + Library().foo() + String(cString: swift_c_module_greeting()) + "\n" + "\(equation) = \(answer)"
    }
}
