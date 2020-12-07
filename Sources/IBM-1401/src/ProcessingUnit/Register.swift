//
//  File.swift
//  
//
//  Created by Martin Albrecht on 13.06.20.
//

class Register {
    private var value: Word = Word()
    private var validityCheck: Bool = false
    private var needCheck: Bool = false
    
    init(hasParityCheck: Bool = false) {
        value = 0 // 0 BCD encoded
        needCheck = false
        validityCheck = hasParityCheck
    }
    
    func get() -> Word {
        self.needCheck = true
        return value
    }
 
    @discardableResult func set(with value: Word) -> Word {
        self.value = value
        self.needCheck = true
        return self.value
    }
    
    func setWordMark() {
        value.setWordMark()
    }
    
    func isValid() -> Bool {
        return validityCheck ? value.parityCheck() && value.isValid() : value.parityCheck()
    }
    
    func isDecimal() -> Bool {
        return self.value & 0b00110000 == 0
    }
}
