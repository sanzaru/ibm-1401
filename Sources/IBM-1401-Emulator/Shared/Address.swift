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

import Foundation

typealias Address = [Word]

extension Address {
    struct ZonePrefix {
        static let zero = ["+", "/", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        static let eleven = ["J", "K", "L", "M", "N", "O", "P", "Q", "R"]
        static let twelve = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
    }
}

extension Address {
    var intValue: Int {
        var addr: Int = 0

        addr += Int(self[2].decoded)
        addr += Int(self[1].decoded) * 10

        // Check for special addressing
        // Addresses above 999 are still addressed via three character addresses on the 1401. Special characters and
        // bit configurations are used to determine the storage address to address

        // 3000 - 3999: 12th zone
        if self[0] & 0b00110000 != 0 {
            if let index = ZonePrefix.twelve.firstIndex(of: String(self[0].char ?? Character(""))) {
                addr += 3100 + (index * 100)
            } else {
                addr += 3000 + Int(self[0].decoded)
            }
        }
        // 2000 - 2999: 11th zone
        else if self[0] & 0b00100000 != 0 {
            if let index = ZonePrefix.eleven.firstIndex(of: String(self[0].char ?? Character(""))) {
                addr += 2100 + (index * 100)
            } else {
                addr += 2000 + Int(self[0].decoded)
            }
        }
        // 1000 - 1999: Zero zone
        else if self[0] & 0b00010000 != 0 {
            let ch = self[0].char ?? Character("")
            if let index = ZonePrefix.zero.firstIndex(of: String(ch)) {
                addr += 1000 + (index * 100)
            }
        }
        // 0 - 999: No zone
        else {
            addr += Int(self[0].decoded) * 100
        }

        let ret = Int(addr)

        return ret
    }
}


extension Address {
    var encoded: Int {
        return intValue > 0 ? intValue - 1 : 0
    }

    var encodedArray: [Int] {
        return map({ $0.intValue })
    }
}


extension Address {
    mutating func increase() {
        let value = self.intValue + 1
        self = value.addressValue
    }

    mutating func decrease() {
        let value = self.intValue - 1
        self = value.addressValue
    }
}


extension Int {
    var addressValue: Address {
        let parts = self.digits.reversed()
        var addr: Address = parts.map { Word($0).encoded }

        while addr.count < 3 {
            addr.append(Word(0).encoded)
        }

        // Replace with special character, if address is above 999
        if self > 999 {
            if self <= 1999 {
                let index = (self % 1000) / 100
                if index <= addr.count {
                    addr[2] = Word(Address.ZonePrefix.zero[index])!.encoded
                }
            } else if self > 1999 && self <= 2999 {
                let index = (self % 2000) / 100
                if index <= addr.count {
                    addr[2] = Word(Address.ZonePrefix.eleven[index])!.encoded
                }
            } else if self > 2999 && self <= 3999 {
                let index = (self % 3000) / 100
                if index <= addr.count {
                    addr[2] = Word(Address.ZonePrefix.twelve[index])!.encoded
                }
            }
        }

        return addr.reversed()
    }
}
