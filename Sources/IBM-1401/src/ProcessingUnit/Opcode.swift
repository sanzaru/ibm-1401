//
//  File.swift
//  
//
//  Created by Martin Albrecht on 03.06.20.
//

extension ProcessingUnit {
    
    /// Opcode definitions
    internal enum Opcodes: Character {
        case setWordMark = ","
        case clearStorage = "/"
        case move = "M"
        case moveDigit = "D"
        case moveZone = "Y"
        case halt = "."
        case noop = "N"
        case load = "L"
    }
    
    // MARK: - E-Phase methods
    
    /// General A-Cycle for execution phases
    private func generalEPhaseCycleA() {
        // A-Addr-Reg to STAR
        registers.addrS = registers.addrA
        
        // Read storage to B-Reg
        var addr = addrToInt(addrIn: registers.addrS)
        registers.b.set(with: coreStorage.get(from: addr))
        
        // Write back to storage
        coreStorage.set(at: addr, with: registers.b.get())
        
        // B-Reg to A-Reg
        registers.a.set(with: registers.b.get())
        
        // Decrease A-Addr-Reg
        addr = addrToInt(addrIn: registers.addrA)
        addr -= 1
        registers.addrA = intToAddr(addrIn: addr)
        
        // FIXME: Implement parity and validity checks...
    }
    
    /// Set word mark instuction
    internal func op_setWordmark() {
        // B-Cycle
        func cycleB() {
            registers.addrS = registers.addrB
            
            var addr = addrToInt(addrIn: registers.addrS, encoded: true)
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Set word mark
            registers.b.setWordMark()
            coreStorage.set(at: addr, with: registers.b.get())
            
            // Decrease B-Address-Register
            addr = addrToInt(addrIn: registers.addrB)
            addr -= 1
            registers.addrB = intToAddr(addrIn: addr)
            
            // FIXME: Implement parity and validity checks...
        }
        
        // A-Cycle
        registers.addrS = registers.addrA
        
        // Read storage into B-Register
        let addr = addrToInt(addrIn: registers.addrS, encoded: true)
        registers.b.set(with: coreStorage.get(from: addr))
        
        if registers.i.get().isOpCode(code: Opcodes.setWordMark.rawValue) {
            dump("RUN SET WORD MARK: \(addr)")
            
            // Set word mark
            registers.b.setWordMark()
            coreStorage.set(at: addr, with: registers.b.get())
            registers.a.set(with: registers.b.get())
            
            // Decrease A-Address-Register
            var addr = addrToInt(addrIn: registers.addrA)
            addr -= 1
            registers.addrA = intToAddr(addrIn: addr)
            
            // FIXME: Implement parity and validity checks...
            
            cycleB()
        }
    }
    
    /// Clear storage instruction
    /// NOTE: This instruction always skips the A-Cycle of the I-Operation
    internal func op_clearStorage() throws {
        var addr = addrToInt(addrIn: registers.addrB)
        
        // Calculate the address the instruction should end
        let end = Int(registers.addrB[0].decode()) * 100
        
        dump("RUNNING CLEAR STORAGE: \(registers.addrB) - From: \(addr) - \(end)...")
        
        // Decrease B-Reg-Addr
        repeat {
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read STAR to B-Reg
            addr = addrToInt(addrIn: registers.addrS)
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Set C-Bit at addr
            coreStorage.setCheckBit(at: addr)
            
            addr = addrToInt(addrIn: registers.addrB)
            addr -= 1
            registers.addrB = intToAddr(addrIn: addr)
            
            // FIXME: Implement parity and validity checks...
        } while addr >= end
    }
    
    /// Halt instruction
    internal func op_halt() throws {
        // Check OP code for decimal
        if !registers.i.isDecimal() {
            // Determine if cycle phase is #4
            iAddrRegBlocked = iPhaseCount == 4
            
            // FIXME: Implement parity and validity checks...
            
            // Stop current execution
            throw(Exceptions.haltSystem)
        }
        
        // Eliminate e-phase
        stopExecutionPhase()
    }
    
    /// Move instruction
    internal func op_move() throws {
        var end = false
        repeat {
            // Run general A-Cycle
            generalEPhaseCycleA()
            
            // B-Cycle
            
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read storage to B-Reg
            var addr = addrToInt(addrIn: registers.addrS)
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Write A-Register to storage and
            coreStorage.set(at: addr, with: registers.a.get() & 0b01111111)
            
            dump("MOVED VALUE TO CORE STORAGE: \(addr) -> \(registers.a.get() & 0b01111111)")
            
            // Check A- and B-Register for WM
            if registers.a.get().hasWordmark() || registers.b.get().hasWordmark() {
                
                // Send WM to core storage if needed
                if registers.b.get().hasWordmark() {
                    var value = registers.a.get() | 0b10000000
                    if !value.parityCheck() {
                        value.setCheckBit()
                    }
                    coreStorage.set(at: addr, with: value)
                }
                
                // Decrease B-Addr-Reg
                addr = addrToInt(addrIn: registers.addrB)
                addr -= 1
                registers.addrB = intToAddr(addrIn: addr)
                
                // FIXME: Implement parity and validity checks...
                
                // End E-Phase
                end = true
            } else {
                // Decrease B-Addr-Reg
                addr = addrToInt(addrIn: registers.addrB)
                addr -= 1
                registers.addrB = intToAddr(addrIn: addr)
                
                // FIXME: Implement parity and validity checks...
            }
        } while !end
    }
    
    /// Move digit instruction
    internal func op_move_digit_zone() throws {
        // Run general A-Cycle
        generalEPhaseCycleA()
        
        // B-Cycle
        
        // B-Addr-Reg to STAR
        registers.addrS = registers.addrB
        
        // Read storage into B-Reg
        var addr = addrToInt(addrIn: registers.addrS)
        registers.b.set(with: coreStorage.get(from: addr))
        
        // Check op code
        var value: Word = 0
        if registers.i.get().isOpCode(code: Opcodes.moveDigit.rawValue) {
            // Move B-Reg WM and zones to new value
            value = 0b10110000 & registers.b.get()
            
            // Move A-Reg digit value to new value
            value &= 0b00001111 & registers.a.get()
        } else {
            // Move B-Reg digit value to new value
            value = 0b00001111 & registers.b.get()
            
            // Move A-Reg WM and zones to new value
            value &= 0b10110000 & registers.a.get()
        }
        
        // Set check bit if needed
        if !value.parityCheck() {
            value.setCheckBit()
        }
        
        // Write new value to storage
        coreStorage.set(at: addr, with: value)
        
        // Decrease B-Addr-Reg
        addr = addrToInt(addrIn: registers.addrB)
        addr -= 1
        registers.addrB = intToAddr(addrIn: addr)
        
        // FIXME: Implement parity and validity checks...
    }
    
    /// Load instruction
    internal func op_load() throws {
        var quit = false
        
        repeat {
            // Run general A-Cycle
            generalEPhaseCycleA()
            
            // B-Cycle
            
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read storage to B-Reg
            var addr = addrToInt(addrIn: registers.addrS)
            registers.b.set(with: coreStorage.get(from: addr))
            
            // A-Reg char and WM to storage
            coreStorage.set(at: addr, with: registers.a.get() & 0b10111111)
            
            // Decrease B-Addr-Reg
            addr = addrToInt(addrIn: registers.addrB)
            addr -= 1
            registers.addrB = intToAddr(addrIn: addr)
            
            // FIXME: Implement parity and validity checks...
            
            // Check for WM in A-Reg
            quit = registers.a.get().hasWordmark()
        } while !quit
    }
    
    /// No operation instruction
    internal func op_noop() throws {
        return
    }
}
