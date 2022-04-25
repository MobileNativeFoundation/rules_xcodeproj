@_implementationOnly import _Lib
import Foundation

@objcMembers
public class SwiftGreetings: NSObject {
    public static func greeting() -> String { String(cString: cc_greeting()) }
}
