//
//  File.swift
//  
//
//  Created by Martin Albrecht on 01.06.20.
//

class ProcessingUnit {
    var coreStorage: PUCoreStorage
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
    
    internal struct Registers {
        var a: PURegister = PURegister()
        var b: PURegister = PURegister()
        var i: PURegister = PURegister()
        var addrA: Address = [74, 74, 74] // 0, 0, 0 BCD encoded
        var addrB: Address = [74, 74, 74]
        var addrI: Address = [0, 0, 0]
        var addrS: Address = [74, 74, 74] // STAR
    }
    
    internal var cyclePhase: CyclePhase = .iPhase
    internal var registers = Registers()
    internal var iAddrRegBlocked: Bool = false
    
    private var ePhaseACycleEliminate: Bool = false
    private var instructionFromRegisterA: Bool = false

    init(storageSize: PUCoreStorage.StorageSize = .k1) {
        coreStorage = PUCoreStorage(size: storageSize)
    }
}


extension ProcessingUnit {
    func step() throws {
        if cyclePhase == .iPhase {
            try instructionNext()
        } else {
            try executionNext()
        }
    }
}


// MARK: - I-Phase
extension ProcessingUnit {
    /// Increase the intruction address, write it to I-Addr-Reg and set STAR to I-Addr-Reg
    private func increaseInstructionAddress() {
        var addr = registers.addrS.intValue
        addr += 1
        registers.addrI = addr.addressValue
        
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
        let addr = registers.addrI.intValue
        
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
            let addr = registers.addrI.intValue
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
            (0..<registers.addrB.count).forEach {
                registers.addrB[$0] = CharacterEncodings[" "]!
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
