import Foundation

extension Date {
    private static let chronicleTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let chronicleDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d/yy HH:mm:ss"
        return f
    }()

    private var milliseconds: String {
        String(format: ".%03d", Int(timeIntervalSinceReferenceDate * 1000) % 1000)
    }

    /// Time only in 24-hour format with milliseconds: `15:42:09.071`
    var chronicle_timeOnly: String {
        Self.chronicleTimeFormatter.string(from: self) + milliseconds
    }

    /// Date and time in 24-hour format with milliseconds: `3/24/26 15:42:09.071`
    var chronicle_formatted: String {
        Self.chronicleDateTimeFormatter.string(from: self) + milliseconds
    }
}
