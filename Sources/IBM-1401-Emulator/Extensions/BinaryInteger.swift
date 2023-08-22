import Foundation

extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { $0.wholeNumberValue }
    }
}
