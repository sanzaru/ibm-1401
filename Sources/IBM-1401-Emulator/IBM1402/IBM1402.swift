import Foundation

final class IBM1402 {
    enum LineSize: Int {
        case normal = 80, stub = 51
    }

    private var readStack = [[UInt8]]()
    private var readIndex = 0

    private let linesize: LineSize

    init(_ linesize: LineSize = .normal) {
        self.linesize = linesize
    }

    func load(from code: [UInt8]) -> [UInt8] {
        readStack = code.chunked(into: linesize.rawValue).reversed()

        #if DEBUG
        dump("Loaded \(readStack.count) cards")
        #endif

        return read()
    }

    func read() -> [UInt8] {
        readStack.popLast() ?? []
    }
}
