import Foundation

extension Error {
    /// For an enum error, the name of the case it is (e.g. `incompleteData`), without its
    /// associated values. Nil for struct, class, and bridged NSError errors.
    var chronicle_caseName: String? {
        let mirror = Mirror(reflecting: self)
        guard mirror.displayStyle == .enum else { return nil }
        if let label = mirror.children.first?.label { return label }   // a case with associated values
        return String(describing: self)                                  // a bare case prints its name
    }
}
