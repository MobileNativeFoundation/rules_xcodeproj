import CustomDump
import XCScheme
import XCTest

final class CreateSchemeManagementTests: XCTestCase {
    func test() {
        // Arrange

        // Order is intentionally odd, to show no sorting happens
        let schemeNames = [
            "ZZ (iOSApp)",
            "a",
            "z <escape me>",
            "B",
        ]

        let expectedSchemeManagement = #"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
		<key>ZZ (iOSApp).xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>0</integer>
		</dict>
		<key>a.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>1</integer>
		</dict>
		<key>z &lt;escape me&gt;.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>2</integer>
		</dict>
		<key>B.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>3</integer>
		</dict>
	</dict>
</dict>
</plist>

"""#

        // Act

        let schemeManagement = CreateSchemeManagement.defaultCallable(
            schemeNames: schemeNames
        )

        // Assert

        XCTAssertNoDifference(schemeManagement, expectedSchemeManagement)
    }
}
