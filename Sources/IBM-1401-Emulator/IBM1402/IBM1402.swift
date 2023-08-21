import Foundation

final class IBM1402 {
    private var readStack = [[UInt8]]()
    private var readIndex = 0

    enum LineSize: Int {
        case normal = 80, stub = 51
    }

    private let linesize = 80 // Can be 51 on some models

    func load(from code: [UInt8]) -> [UInt8] {
        readStack = code.chunked(into: 80).reversed()

        #if DEBUG
        dump("Loaded \(readStack.count) cards")
        #endif

        return read()
    }

    func read() -> [UInt8] {
        readStack.popLast() ?? []
    }
}
