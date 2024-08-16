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
        ("testParityCheck", testParityCheck),
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
        Lib1401.CharacterEncodings.shared.simh.forEach { index, char in
            XCTAssert(char.parityCheck, "Parity test failed for character \(index) with bit count: \(char.bitsSetCount)")

            var wm: Word = Lib1401.CharacterEncodings.shared.simh["A"]!
            wm.setWordMark()
            XCTAssert(wm.parityCheck, "Parity test failed for character A (with WM) with bit count: \(wm.bitsSetCount)")
        }
    }

    func testValidityCheck() throws {
        Lib1401.CharacterEncodings.shared.simh.forEach { index, char in
            XCTAssert(char.valid, "Validity test failed for character \(index): \(char.binaryString)")
        }
    }
}
