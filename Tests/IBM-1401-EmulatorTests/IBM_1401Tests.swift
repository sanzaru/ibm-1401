import XCTest
import class Foundation.Bundle

final class IBM_1401Tests: XCTestCase {
    func testProcessExecution() throws {
        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("IBM-1401-Emulator")

        try process.run()
        process.terminate()
        process.waitUntilExit()

        XCTAssertFalse(process.isRunning)
    }

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
    ]
}
