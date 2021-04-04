//
//  File.swift
//  
//
//  Created by Martin Albrecht on 20.06.20.
//

typealias Word = UInt8
extension Word {
    var isNegative: Bool {
        (self & 0b00100000) == 0b00100000
    }

    var isBlank: Bool {
        self & 0b01000000 == 0
    }

    var hasWordmark: Bool {
        self & 0b10000000 == 0b10000000
    }

    var bitCount: Int {
        var count = 0

        for i in 0...7 {
            if self >> i & 1 == 1 {
                count += 1
            }
        }

        return count
    }

    var isValid: Bool {
        var check = false
        CharacterEncodings.forEach { _, value in
            if (self & 0b00111111) & (value & 0b00111111) == 0 {
                check = true
                return
            }
        }

        return check
    }

    var parityCheck: Bool {
        var count = 0

        for i in 0...6 {
            if (self >> i) & 1 == 1 {
                count += 1
            }
        }

        return count % 2 != 0
    }

    var dropWordmark: Word {
        self & 0b01111111
    }

    var char: Character? {
        for (key, value) in CharacterEncodings {
            if (self & 0b00111111) ^ (value & 0b00111111) == 0 {
                return key
            }
        }

        return nil
    }

    var decoded: Word {
        for (key, value) in CharacterEncodings {
            if value.dropWordmark == dropWordmark {
                return Word(String(key)) ?? 0
            }
        }

        return 0
    }

    var intValue: Int {
        let val = self.decoded
        return isNegative ? Int(val)*(-1) : Int(val)
    }

    var encoded: Word {
        for (key, value) in CharacterEncodings {
            if String(key) == String(self) {
                return hasWordmark ? value ^ 0b10000000 : value
            }
        }

        return 0
    }

    var binaryString: String {
        var str = ""
        for i in 0...7 {
            str += self >> i & 1 == 1 ? "1" : "0"
        }

        return String(str.reversed())
    }

    func isOpCode(code: Character) -> Bool {
        if let c = CharacterEncodings[code] {
            //dump("IS OP CODE: \((self & 0b00111111)) -> \((c & 0b00111111)) => \((self & 0b00111111) ^ (c & 0b00111111))")

            // Drop WM and C bit from both sides
            return (self & 0b00111111) ^ (c & 0b00111111) == 0
        }
        
        return false
    }
    
    // MARK: - Mutating
    @discardableResult mutating func setWordMark() -> Word {
        self |= 0b10000000
        
        if !parityCheck {
            self ^= 0b01000000
        }
        
        return self
    }
    
    @discardableResult mutating func setCheckBit() -> Word {
        self |= 0b01000000
        
        if !parityCheck {
            self ^= 0b01000000
        }
        
        return self
    }    
}
