//
//  File.swift
//  
//
//  Created by Martin Albrecht on 20.06.20.
//

typealias Word = UInt8
extension Word {
    func isOpCode(code: Character) -> Bool {
        if let c = CharacterEncodings[code] {
            // Drop WM and C bit from both sides
            //dump("IS OP CODE: \((self & 0b00111111)) -> \((c & 0b00111111)) => \((self & 0b00111111) ^ (c & 0b00111111))")
            return (self & 0b00111111) ^ (c & 0b00111111) == 0
        }
        
        return false
    }
    
    func char() -> Character? {
        for (key, value) in CharacterEncodings {
            if (self & 0b00111111) ^ (value & 0b00111111) == 0 {
                return key
            }
        }
        
        return nil
    }
    
    func dropWordmark() -> Word {
        return self & 0b01111111
    }
    
    func decode() -> Word {
        for (key, value) in CharacterEncodings {
            if value.dropWordmark() == self.dropWordmark() {
                return Word(String(key)) ?? 0
            }
        }
        
        return 0
    }
    
    func isNegative() -> Bool {
        return (self & 0b00100000) == 0b00100000
    }
    
    func toInt() -> Int {
        let val = self.decode()
        return isNegative() ? Int(val)*(-1) : Int(val)
    }
    
    func encode() -> Word {
        for (key, value) in CharacterEncodings {
            if String(key) == String(self) {
                return self.hasWordmark() ? value ^ 0b10000000 : value
            }
        }
        
        return 0
    }
    
    func isBlank() -> Bool {
        return self & 0b01000000 == 0
    }
    
    func hasWordmark() -> Bool {
        return self & 0b10000000 == 0b10000000
    }
    
    func bitCount() -> Int {
        var count = 0
        
        for i in 0...7 {
            if self >> i & 1 == 1 {
                count += 1
            }
        }
        
        return count
    }
    
    func isValid() -> Bool {
        var check = false
        CharacterEncodings.forEach { _, value in
            if (self & 0b00111111) & (value & 0b00111111) == 0 {
                check = true
                return
            }
        }
        
        return check
    }
    
    func parityCheck() -> Bool {
        var count = 0
        
        for i in 0...6 {
            if (self >> i) & 1 == 1 {
                count += 1
            }
        }
        
        return count % 2 != 0
    }
    
    func binaryString() -> String {
        var str = ""
        for i in 0...7 {
            str += self >> i & 1 == 1 ? "1" : "0"
        }
        
        return String(str.reversed())
    }
    
    // MARK: - Mutating
    @discardableResult mutating func setWordMark() -> Word {
        self |= 0b10000000
        
        if !self.parityCheck() {
            self ^= 0b01000000
        }
        
        return self
    }
    
    @discardableResult mutating func setCheckBit() -> Word {
        self |= 0b01000000
        
        if !self.parityCheck() {
            self ^= 0b01000000
        }
        
        return self
    }    
}
