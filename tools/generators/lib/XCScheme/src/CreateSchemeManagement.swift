public struct CreateSchemeManagement {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates the XML for an `xcschememanagement.plist` file.
    public func callAsFunction(schemeNames: [String]) -> String {
        return callable(/*schemeNames:*/ schemeNames)
    }
}

// MARK: - CreateSchemeManagement.Callable

extension CreateSchemeManagement {
    public typealias Callable = (_ schemeNames: [String]) -> String

    public static func defaultCallable(schemeNames: [String]) -> String {
        // Tabs for indentation is intentional
        return #"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
\#(schemeNames.enumerated().map(createSchemeUserStateElement).joined())\#
	</dict>
</dict>
</plist>

"""#
    }
}

private func createSchemeUserStateElement(
    index: Int,
    schemeName: String
) -> String {
    // Tabs for indentation is intentional
    return #"""
		<key>\#(schemeName.schemeXmlEscaped).xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>\#(index)</integer>
		</dict>

"""#
}
