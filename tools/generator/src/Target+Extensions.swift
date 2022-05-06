extension Target {
    /// The normalized name is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedName: String {
        return name.lowercased()
    }

    /// The normalized label is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedLabel: String {
        return label.lowercased()
    }
}
