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
    struct CoreStorage {
        var count: Int {
            storage.count
        }

        private let size: StorageSize
        private var storage = [Word]()

        enum StorageSize: Int {
            case k1 = 1400
            case k2 = 2000
            case k4 = 4000
            case k8 = 8000
            case k12 = 12000
            case k16 = 16000
        }

        init(size: StorageSize) {
            for _ in 0...(size.rawValue-1) {
                self.storage.append(0b01000000)
            }

            self.size = size
        }

        mutating func get(from addr: Int, setZero: Bool = true) -> Word {
            if addr <= storage.count {
                let item = storage[addr]

                if setZero {
                    storage[addr] &= 0b01000000
                }

                return item
            }

            return 0
        }

        mutating func get(from range: ClosedRange<Int>, setZero: Bool = true) -> [Word] {
            return range.map({ get(from: $0, setZero: setZero) })
        }

        mutating func getPrintStorage() -> [Word] {
            return get(from: 200...300, setZero: false)
        }

        mutating func set(at addr: Int, with value: Word) {
            if addr <= storage.count {
                storage[addr] = storage[addr].hasWordmark ? value | 0b10000000 : value
            }
        }

        mutating func setWordMark(at addr: Int) {
            if addr <= storage.count {
                storage[addr].setWordMark()
            }
        }

        mutating func setCheckBit(at addr: Int) {
            if addr <= storage.count {
                storage[addr].setCheckBit()
            }
        }

        mutating func reset() {
            for i in 0...(size.rawValue-1) {
                self.storage[i] = 0b01000000
            }
        }
    }
}
