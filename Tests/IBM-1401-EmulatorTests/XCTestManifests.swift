import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(IBM_1401Tests.allTests)
    ]
}
#endif
