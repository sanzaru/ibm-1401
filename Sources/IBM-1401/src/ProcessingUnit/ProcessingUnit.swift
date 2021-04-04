//
//  File.swift
//  
//
//  Created by Martin Albrecht on 01.06.20.
//

class ProcessingUnit {
    var coreStorage: CoreStorage
    var iPhaseCount: Int = 0
    
    internal enum CyclePhase {
        case iPhase, ePhase
    }
    
    internal enum Exceptions: Error {
        case parityCheckFail(count: Int, value: Word)
        case stopCondition(String)
        case haltSystem
    }
    
    internal enum ExecutionMode {
        case addressStop, singleCycleProcess, characterDisplay, alter, run,
             iex, storagePrintOut, singleCycleNonProcess, storageScan
    }
    
    internal struct RegisterTypes {
        var a: Register = Register()
        var b: Register = Register()
        var i: Register = Register()
        var addrA:[Word] = [74, 74, 74] // 0, 0, 0 BCD encoded
        var addrB:[Word] = [74, 74, 74]
        var addrI:[Word] = [0, 0, 0]
        var addrS:[Word] = [74, 74, 74] // STAR
    }
    
    internal var cyclePhase: CyclePhase = .iPhase
    internal var registers = RegisterTypes()
    internal var iAddrRegBlocked: Bool = false
    
    private var ePhaseACycleEliminate: Bool = false
    private var instructionFromRegisterA: Bool = false
    
    private struct AddressZonePrefix {
        static let zero = ["+", "/", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        static let eleven = ["J", "K", "L", "M", "N", "O", "P", "Q", "R"]
        static let twelve = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
    }
    
    // MARK: - Methods
    init(storageSize: CoreStorage.StorageSize = .k1) {
        coreStorage = CoreStorage(size: storageSize)
    }
    
    func step() throws {
        if cyclePhase == .iPhase {
            try instructionNext()
        } else {
            try executionNext()
        }
    }
    
    
    // MARK: - Internal methods
    internal func addrToInt(addrIn: [Word], encoded: Bool = false) -> Int {
        var addr: Int = 0
            
        addr += Int(addrIn[2].decoded)
        addr += Int(addrIn[1].decoded) * 10
        
        // Check for special addressing
        // Addresses above 999 are still addressed via three character addresses on the 1401. Special characters and
        // bit configurations are used to determine the storage address to address
        
        // 3000 - 3999: 12th zone
        if addrIn[0] & 0b00110000 != 0 {
            if let index = AddressZonePrefix.twelve.firstIndex(of: String(addrIn[0].char ?? Character(""))) {
                addr += 3100 + (index * 100)
            } else {
                addr += 3000 + Int(addrIn[0].decoded)
            }
        }
        // 2000 - 2999: 11th zone
        else if addrIn[0] & 0b00100000 != 0 {
            if let index = AddressZonePrefix.eleven.firstIndex(of: String(addrIn[0].char ?? Character(""))) {
                addr += 2100 + (index * 100)
            } else {
                addr += 2000 + Int(addrIn[0].decoded)
            }
        }
        // 1000 - 1999: Zero zone
        else if addrIn[0] & 0b00010000 != 0 {
            let ch = addrIn[0].char ?? Character("")
            if let index = AddressZonePrefix.zero.firstIndex(of: String(ch)) {
                addr += 1000 + (index * 100)
            }
        }
        // 0 - 999: No zone
        else {
            addr += Int(addrIn[0].decoded) * 100
        }
        
        let ret = Int(addr)
        if encoded {
            return ret > 0 ? ret - 1 : 0
        }
        
        return ret
    }
    
    internal func intToAddr(addrIn: Int) -> [Word] {
        var addr = [Word]()
        let parts = addrIn.digits.reversed()
        
        for p in parts {
            addr.append(Word(p).encoded)
        }
        
        while addr.count < 3 {
            addr.append(Word(0).encoded)
        }
        
        // Replace with special character, if address is above 999
        if addrIn > 999 {
            if addrIn <= 1999 {
                let index = (addrIn % 1000) / 100
                if index <= addr.count {
                    addr[2] = Word(AddressZonePrefix.zero[index])!.encoded
                }
            } else if addrIn > 1999 && addrIn <= 2999 {
                let index = (addrIn % 2000) / 100
                if index <= addr.count {
                    addr[2] = Word(AddressZonePrefix.eleven[index])!.encoded
                }
            } else if addrIn > 2999 && addrIn <= 3999 {
                let index = (addrIn % 3000) / 100
                if index <= addr.count {
                    addr[2] = Word(AddressZonePrefix.twelve[index])!.encoded
                }
            }
        }
        
        return addr.reversed()
    }
}


// MARK: - I-Phase
extension ProcessingUnit {
    /// Increase the intruction address, write it to I-Addr-Reg and set STAR to I-Addr-Reg
    private func increaseInstructionAddress() {
        var addr = addrToInt(addrIn: registers.addrS)
        addr += 1
        registers.addrI = intToAddr(addrIn: addr)
        
        // FIXME: Implement parity and validity checks...
        
        // Write I-Addr-Reg back to STAR
        // TODO: Must not be done on single cycle instructions
        registers.addrS = registers.addrI
    }
    
    /// General I-Cycle start routine
    /// This function fetches the address from the I-Addr-Register, writes it to STAR and fetches the item stored
    /// at the address into the B-Register
    ///
    /// NOTE: This logic happens in any I-Cycle except the first (i-OP)
    ///
    /// - Returns: Addr read from the I-Addr-Reg
    private func cycleIStart() -> Int {
        let addr = addrToInt(addrIn: registers.addrI)
        
        // Write address to STAR
        registers.addrS = registers.addrI
        
        // Read storage position into B-Reg
        registers.b.set(with: coreStorage.get(from: addr))
        
        // Write item back to storage
        coreStorage.set(at: addr, with: registers.b.get())
        
        return addr
    }
    
    
    // MARK: - Private I-Phase cycles
    private func instructionNext() throws {
        switch iPhaseCount {
        case 0:
            let addr = addrToInt(addrIn: registers.addrI)
            dump("ADDR I-OP: \(addr) : \(registers.addrI)")
            dump("I-IO REG: \(iAddrRegBlocked ? "Blocked" : "Open")")
            
            // Write address to STAR
            if iAddrRegBlocked {
                registers.addrS = registers.addrA
                iAddrRegBlocked = false
            } else {
                registers.addrS = registers.addrI
            }
            
            // Read storage position into B-Reg
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Write item back to storage
            coreStorage.set(at: addr, with: registers.b.get())
            
            // Fetch instruction from address, drop word mark and reverse C-Bit
            registers.i.set(with: (registers.b.get() & 0b01111111) ^ 0b01000000)
            
            dump("I-OP Instruction: \(registers.i):\(registers.i.get().char ?? Character(""))")
            
        case 1, 2:
            let addr = cycleIStart()
            dump("ADDR I-\(iPhaseCount == 1 ? "1" : "2"): \(addr) : \(registers.addrI)")
            
            // Check for WM in B-Reg
            if !registers.b.get().hasWordmark {
                registers.a.set(with: registers.b.get())
                
                // Set A-Addr-Reg
                registers.addrA[iPhaseCount-1] = registers.b.get()
                
                // Check for specific OP-Code. If we don't have a special op code, we write the
                // value from B-Register to the correct B-Addr-Reg position
                if !registers.i.get().isOpCode(code: "L") && !registers.i.get().isOpCode(code: Opcodes.move.rawValue) &&
                    !registers.i.get().isOpCode(code: "Q") && !registers.i.get().isOpCode(code: "H") {
                    registers.addrB[iPhaseCount == 1 ? 0 : 1] = registers.b.get()
                }
            } else {
                // FIXME: Check for specific OP code
                
                if registers.i.get().isOpCode(code: Opcodes.noop.rawValue) {
                    stopExecutionPhase()
                    
                    // FIXME: Implement parity and validity checks...
                } else {
                    // FIXME: Implement parity and validity checks...
                    
                    cyclePhase = .ePhase
                }
            }
            
        case 3:
            let addr = cycleIStart()
            dump("ADDR I-3: \(addr) : \(registers.addrI)")
            
            registers.a.set(with: registers.b.get())
            
            // Set A-Addr-Reg
            registers.addrA[2] = registers.b.get()
            
            // Check for specific OP-Code. If we don't have a special op code, we write the
            // value from B-Register to the correct B-Addr-Reg position
            if !registers.i.get().isOpCode(code: "L") && !registers.i.get().isOpCode(code: Opcodes.move.rawValue) &&
                !registers.i.get().isOpCode(code: "Q") && !registers.i.get().isOpCode(code: "H") {
                registers.addrB[2] = registers.b.get()
            }
            
        case 4:
            let addr = cycleIStart()
            dump("ADDR I-4: \(addr) : \(registers.addrI)")
            
            // Check for branch opcode
            if (registers.i.get().isOpCode(code: "B") && (registers.b.get().isBlank || registers.b.get().hasWordmark) ) {
                // TODO: Implement branch instruction handling
                return
            }
            
            // Check WM in B-Register
            if registers.b.get().hasWordmark {
                // FIXME: Implement op code handling
                #if DEBUG
                    dump("WORD MARK IS SET: \(registers.b.get())")
                #endif
                
                if registers.i.get().isOpCode(code: Opcodes.clearStorage.rawValue) {
                    ePhaseACycleEliminate = true
                }
                
                // FIXME: Implement parity and validity checks...
                
                cyclePhase = .ePhase
                return
            }
            
            registers.a.set(with: registers.b.get())
            
            // Set B-Addr-Register to blanks
            for i in 0...(registers.addrB.count-1) {
                registers.addrB[i] = CharacterEncodings[" "]!
            }
            
            registers.addrB[0] = registers.b.get()
            
        case 5:
            let addr = cycleIStart()
            #if DEBUG
                dump("ADDR I-5: \(addr) : \(registers.addrI)")
            #endif
            
            // Check B-Register for WM
            if registers.b.get().hasWordmark {
                // FIXME: Check for specific OP code
                // FIXME: Implement parity and validity checks...
                
                cyclePhase = .ePhase
                return
            }
            
            registers.a.set(with: registers.b.get())
            registers.addrB[1] = registers.b.get()
            
        case 6:
            let addr = cycleIStart()
            dump("ADDR I-6: \(addr) : \(registers.addrI)")
            
            registers.a.set(with: registers.b.get())
            registers.addrB[2] = registers.b.get()
            
        case 7:
            let addr = cycleIStart()
            dump("ADDR I-7: \(addr) : \(registers.addrI)")
            
            // Check for set word mark opcode
            if registers.i.get().isOpCode(code: Opcodes.setWordMark.rawValue) {
                cyclePhase = .ePhase
            } else if registers.i.get().isOpCode(code: Opcodes.clearStorage.rawValue) {
                iAddrRegBlocked = true
                ePhaseACycleEliminate = true
                cyclePhase = .ePhase
            } else {
                // Check B-Register for WM
                if registers.b.get().hasWordmark {
                    // FIXME: Implement op code handling
                    cyclePhase = .ePhase
                    return
                }
                
                registers.a.set(with: registers.b.get())
            }
            
        case 8:
            cycleIOp8()
            return
            
        default:
            return
        }
        
        // Increase intruction address and write it to I-Addr-Reg
        if cyclePhase == .iPhase {
            increaseInstructionAddress()
            // FIXME: Implement parity and validity checks...
            iPhaseCount += 1
        }
    }
    
    private func cycleIOp8() {
        let addr = cycleIStart()
        dump("ADDR I-8: \(addr) : \(registers.addrI)")
        
        if registers.b.get().hasWordmark {
            // FIXME: Implement op code handling
            return
        }
        
        registers.a.set(with: registers.b.get())
        
        // Increase intruction address and write it to I-Addr-Reg
        increaseInstructionAddress()
        
        cycleIOp8()
    }
}


// MARK: - E-Phase
extension ProcessingUnit {
    internal func stopExecutionPhase() {
        iPhaseCount = 0
        cyclePhase = .iPhase
    }
    
    private func executionNext() throws {
        dump("E-PHASE: \(registers.i.get().char ?? Character(""))")
        
        if registers.i.get().isOpCode(code: Opcodes.setWordMark.rawValue) {
            op_setWordmark()
        }
        
        else if registers.i.get().isOpCode(code: Opcodes.clearStorage.rawValue) {
            try op_clearStorage()
            ePhaseACycleEliminate = false
            iAddrRegBlocked = false
        }
            
        else if registers.i.get().isOpCode(code: Opcodes.move.rawValue) {
            try op_move()
        }
            
        else if registers.i.get().isOpCode(code: Opcodes.moveDigit.rawValue) || registers.i.get().isOpCode(code: Opcodes.moveZone.rawValue) {
            try op_move_digit_zone()
        }
            
        else if registers.i.get().isOpCode(code: Opcodes.load.rawValue) {
            try op_load()
        }
            
        else if registers.i.get().isOpCode(code: Opcodes.halt.rawValue) {
            try op_halt()
        }
        
        else {
            throw Exceptions.stopCondition("E-PHASE ERROR: INSRUCTION NOT IMPLEMENTED OR UNKNOWN: \(registers.i.get().char ?? Character(""))")
        }
        
        stopExecutionPhase()
    }
}


// MARK: - Monitor
extension ProcessingUnit {
    var monitorData: MonitorData {
        MonitorData(
            registerA: registers.a.get(),
            registerB: registers.b.get(),
            registerI: registers.i.get(),
            registerAddrA: registers.addrA,
            registerAddrB: registers.addrB,
            registerAddrI: registers.addrI,
            registerAddrS: registers.addrS,
            instructionCounter: iPhaseCount
        )
    }
}
