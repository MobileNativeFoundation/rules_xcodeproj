@freestanding(declaration, names: arbitrary)
public macro Injectable(asStatic: Bool = false, wrappedFunction: () -> Void) =
    #externalMacro(module: "GeneratorCommonMacros", type: "InjectableMacro")
