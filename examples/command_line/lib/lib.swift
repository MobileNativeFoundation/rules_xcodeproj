@_implementationOnly import _Lib
import ExternalFramework
import Foundation
import ImportableLibrary

@objcMembers
public class SwiftGreetings: NSObject {
    public static func greeting() -> String {
        return String(cString: cc_greeting()) + Baz.bar + Library().foo()
    }
}
