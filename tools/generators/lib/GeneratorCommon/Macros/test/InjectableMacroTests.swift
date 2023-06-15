//import GeneratorCommonMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "Injectable": InjectableMacro.self
]

class InjectableMacroTests: XCTestCase {
    func test_indents() {
        assertMacroExpansion(
            """
#Injectable {
    /// Is this foo?
    func fooWoo(
        bar: String,
        baz: Int
    ) -> (
        String,
        Bool
    ) {
        func innerFunc(
            a: Int,
            b: Bool
        ) -> (
            a: Int,
            b: Bool
        ) {
            return (
                a,
                b
            )
        }

        if false {
            return ("true", true)
        } else {
            print("Hi")
        }

        let d = (0..<3).map { number in
            return number * 5
                + 2
        }

        guard baz == 42 else {
            return ("", false)
        }

        for i in 0..<4 {
            print(i)
        }

        let e = NSString(
            string: "eeeee"
        ).standardizingPath

        while let symlinkDest = try? fileManager
            .destinationOfSymbolicLink(atPath: pathToResolve)
        {
            print("Resolving")
        }

        switch bar {
        case "hello":
            if true {
                return ("false", false)
            } else {
                print("Goodbye")
            }

        default:
            break
        }

        return ("false", false)
    }
}
""",
            expandedSource: """

/// Is this foo?
func fooWoo(
    bar: String,
    baz: Int
) -> (
    String,
    Bool
) {
    func innerFunc(
        a: Int,
        b: Bool
    ) -> (
        a: Int,
        b: Bool
    ) {
        return (
            a,
            b
        )
    }

    if false {
        return ("true", true)
    } else {
        print("Hi")
    }

    let d = (0 ..< 3).map { number in
        return number * 5
                        + 2
    }

    guard baz == 42 else {
        return ("", false)
    }

    for i in 0 ..< 4 {
        print(i)
    }

    let e = NSString(
        string: "eeeee"
    ).standardizingPath

    while let symlinkDest = try? fileManager
    .destinationOfSymbolicLink(atPath: pathToResolve)
    {
        print("Resolving")
    }

    switch bar {
    case "hello":
        if true {
            return ("false", false)
        } else {
            print("Goodbye")
        }

    default:
        break
    }

    return ("false", false)
}

struct FooWoo {
    typealias Callable = (_ bar: String, _ baz: Int) -> (
        String,
        Bool
    )

    private let callable: Callable

    init(callable: @escaping Callable = fooWoo) {
        self.callable = callable
    }

    /// Is this foo?
    func callAsFunction(
        bar: String,
        baz: Int
    ) -> (
        String,
        Bool
    ) {
        return callable(bar, baz)
    }
}
""",
            macros: testMacros
        )
    }

    func test_nonTrailingClosure() {
        assertMacroExpansion(
            """
#Injectable(wrappedFunction: {
    func a() {}
})
""",
            expandedSource: """

func a() {
}

struct A {
    typealias Callable = () -> Void

    private let callable: Callable

    init(callable: @escaping Callable = a) {
        self.callable = callable
    }

    func callAsFunction() {
        callable()
    }
}
""",
            macros: testMacros
        )
    }

    func test_noReturn() {
        assertMacroExpansion(
            """
#Injectable {
    func bar() {
    }
}
""",
            expandedSource: """

func bar() {
}

struct Bar {
    typealias Callable = () -> Void

    private let callable: Callable

    init(callable: @escaping Callable = bar) {
        self.callable = callable
    }

    func callAsFunction() {
        callable()
    }
}
""",
            macros: testMacros
        )
    }

    func test_throwing() {
        assertMacroExpansion(
            """
#Injectable {
    func throwing() throws {
        throw ErrorThing(
            message: "NOOOO!"
        )
    }
}
""",
            expandedSource: """

func throwing() throws {
    throw ErrorThing(
        message: "NOOOO!"
    )
}

struct Throwing {
    typealias Callable = () throws -> Void

    private let callable: Callable

    init(callable: @escaping Callable = throwing) {
        self.callable = callable
    }

    func callAsFunction() throws {
        try callable()
    }
}
""",
            macros: testMacros
        )
    }

    func test_nestedStaticFunc() {
        assertMacroExpansion(
            """
extension Parent.Child {
    #Injectable(asStatic: true) {
        /// Meet at the bar
        func baz(_ bar: String, foo oof: Int) -> Int {
            return 42
        }
    }
}
""",
            expandedSource: """
extension Parent.Child {
    /// Meet at the bar
    static func baz(_ bar: String, foo oof: Int) -> Int {
        return 42
    }

    struct Baz {
        typealias Callable = (_ bar: String, _ oof: Int) -> Int

        private let callable: Callable

        init(callable: @escaping Callable = baz) {
            self.callable = callable
        }

        /// Meet at the bar
        func callAsFunction(_ bar: String, foo oof: Int) -> Int {
            return callable(bar, oof)
        }
    }
}
""",
            macros: testMacros
        )
    }

    func test_error_noStatements() {
        assertMacroExpansion(
            """
#Injectable {
}
""",
            expandedSource: """
""",
            diagnostics: [
                .init(
                    message: "#Injectable must wrap a single function",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_error_tooManyStatements() {
        assertMacroExpansion(
            """
#Injectable {
    let a = true
    let b = false
}
""",
            expandedSource: """
""",
            diagnostics: [
                .init(
                    message: "#Injectable must wrap a single function",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_error_notAFunction() {
        assertMacroExpansion(
            """
#Injectable {
    let a = true
}
""",
            expandedSource: """
""",
            diagnostics: [
                .init(
                    message: "#Injectable must wrap a function",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
