import Foundation

struct Logger {
    static func debug(_ message: String) {
        #if DEBUG
        print("[DEBUG]: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
        #endif
    }

    static func info(_ message: String) {
        print("[INFO]: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    static func error(_ message: String) {
        print("[ERROR]: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
}
