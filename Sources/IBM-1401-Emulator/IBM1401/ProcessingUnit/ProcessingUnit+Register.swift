// Copyright 2023 Martin Albrecht
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
