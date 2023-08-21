
extension ProcessingUnit {
    struct Register {
        var isValid: Bool {
            validityCheck ? value.parityCheck && value.valid : value.parityCheck
        }

        var isDecimal: Bool {
            value & 0b00110000 == 0
        }

        private var value: Word = Word()
        private var validityCheck: Bool = false
        private var needCheck: Bool = false

        init(hasParityCheck: Bool = false) {
            value = 0 // 0 BCD encoded
            needCheck = false
            validityCheck = hasParityCheck
        }

        mutating func get() -> Word {
            needCheck = true
            return value
        }

        @discardableResult
        mutating func set(with value: Word) -> Word {
            self.value = value
            needCheck = true
            return self.value
        }

        mutating func setWordMark() {
            value.setWordMark()
        }
    }
}
