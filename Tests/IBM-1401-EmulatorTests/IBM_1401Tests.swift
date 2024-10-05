import XCTest
import class Foundation.Bundle
import Lib1401

@testable import IBM_1401_Emulator

final class IBM_1401Tests: XCTestCase {
    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("testProcessExecution", testProcessExecution),
        ("testParityCheck", testParityCheck)
    ]
}

// MARK: General tests
extension IBM_1401Tests {
    func testProcessExecution() throws {
        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("IBM-1401-Emulator")

        try process.run()
        process.terminate()
        process.waitUntilExit()

        XCTAssertFalse(process.isRunning)
    }
}

// MARK: Word tests
extension IBM_1401Tests {
    func testParityCheck() throws {
        Lib1401.CharacterEncodings.shared.simh.forEach {
            XCTAssert($0.value.parityCheck, "Parity test failed for character \($0.value) with key \($0.key) with bit count: \($0.value.bitsSetCount)")

            var wm: Word = Lib1401.CharacterEncodings.shared.simh["A"]!
            wm.setWordMark()
            XCTAssert(wm.parityCheck, "Parity test failed for character A (with WM) with bit count: \(wm.bitsSetCount)")
        }
    }

    func testValidityCheck() throws {
        Lib1401.CharacterEncodings.shared.simh.forEach {
            XCTAssert($0.value.valid, "Validity test failed for character \($0.key): \($0.value) \($0.value.binaryString)")
        }
    }

    func testBitCount() throws {
        let values: [Character: Int] = ["I": 5, "X": 5, "A": 3, "\"": 7]

        values.forEach {
            let value = Lib1401.CharacterEncodings.shared.simh[$0.key]
            let count = value?.bitsSetCount ?? 0
            XCTAssertEqual(count, $0.value, "Bit count failed for character \($0.key): expected \($0.value), got \(count)")
        }
    }
}
