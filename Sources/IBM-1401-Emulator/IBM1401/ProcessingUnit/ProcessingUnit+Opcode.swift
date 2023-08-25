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

import Lib1401
import Foundation

/// Opcode definitions
extension ProcessingUnit {
    internal enum Opcodes: Character {
        case setWordMark = ","
        case clearStorage = "/"
        case move = "M"
        case moveDigit = "D"
        case moveZone = "Y"
        case halt = "."
        case noop = "N"
        case load = "L"
        case print = "2"
        case readCard = "1"
    }
}


// MARK: - E-Phase methods
extension ProcessingUnit {
    /// General A-Cycle for execution phases
    private func generalEPhaseCycleA() {
        // A-Addr-Reg to STAR
        registers.addrS = registers.addrA
        
        // Read storage to B-Reg
        var addr = registers.addrS.intValue
        registers.b.set(with: coreStorage.get(from: addr, setZero: false))
        
        // Write back to storage
        coreStorage.set(at: addr, with: registers.b.get())
        
        // B-Reg to A-Reg
        registers.a.set(with: registers.b.get())
        
        // Decrease A-Addr-Reg
        addr = registers.addrA.intValue
        addr -= 1
        registers.addrA = addr.addressValue
        
        // FIXME: Implement parity and validity checks...
    }
}


// MARK: - Instructions


/// Set word mark instuction
extension ProcessingUnit {
    internal func op_setWordmark() {
        // B-Cycle
        func cycleB() {
            registers.addrS = registers.addrB
            
            var addr = registers.addrS.encoded
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Set word mark
            registers.b.setWordMark()
            coreStorage.set(at: addr, with: registers.b.get())
            
            // Decrease B-Address-Register
            addr = registers.addrB.intValue
            addr -= 1
            registers.addrB = addr.addressValue
            
            // FIXME: Implement parity and validity checks...
        }
        
        // A-Cycle
        registers.addrS = registers.addrA
        
        // Read storage into B-Register
        let addr = registers.addrS.encoded
        registers.b.set(with: coreStorage.get(from: addr))
        
        if registers.i.get().isOpCode(code: Opcodes.setWordMark.rawValue) {
            Logger.debug("RUN SET WORD MARK: \(addr)")

            // Set word mark
            registers.b.setWordMark()
            coreStorage.set(at: addr, with: registers.b.get())
            registers.a.set(with: registers.b.get())
            
            // Decrease A-Address-Register
            var addr = registers.addrA.intValue
            addr -= 1
            registers.addrA = addr.addressValue
            
            // FIXME: Implement parity and validity checks...
            
            cycleB()
        }
    }
}


/// Clear storage instruction
/// NOTE: This instruction always skips the A-Cycle of the I-Operation
extension ProcessingUnit {
    internal func op_clearStorage() throws {
        var addr = registers.addrB.intValue
        
        // Calculate the address the instruction should end
        let end = Int(registers.addrB[0].decoded) * 100
        
        Logger.debug("RUNNING CLEAR STORAGE: \(registers.addrB) - From: \(addr) - \(end)...")

        // Decrease B-Reg-Addr
        repeat {
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read STAR to B-Reg
            addr = registers.addrS.intValue
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Set C-Bit at addr
            coreStorage.setCheckBit(at: addr)
            
            addr = registers.addrB.intValue
            addr -= 1
            registers.addrB = addr.addressValue
            
            // FIXME: Implement parity and validity checks...
        } while addr >= end
    }
}

/// Halt instruction
extension ProcessingUnit {
    internal func op_halt() throws {
        // Check OP code for decimal
        if !registers.i.isDecimal {
            // Determine if cycle phase is #4
            iAddrRegBlocked = iPhaseCount == 4
            
            // FIXME: Implement parity and validity checks...
            
            // Stop current execution
            throw(Exceptions.haltSystem)
        }
        
        // Eliminate e-phase
        stopExecutionPhase()
    }
}

/// Move instruction
extension ProcessingUnit {
    internal func op_move() throws {
        var end = false
        repeat {
            // Run general A-Cycle
            generalEPhaseCycleA()
            
            // B-Cycle
            
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read storage to B-Reg
            var addr = registers.addrS.intValue
            registers.b.set(with: coreStorage.get(from: addr))
            
            // Write A-Register to storage and
            coreStorage.set(at: addr, with: registers.a.get() & 0b01111111)
            
            Logger.debug("MOVED VALUE TO CORE STORAGE: \(addr) -> \(registers.a.get() & 0b01111111) (\(registers.a.get().char ?? Character("")))")
            
            // Check A- and B-Register for WM
            if registers.a.get().hasWordmark || registers.b.get().hasWordmark {
                
                // Send WM to core storage if needed
                if registers.b.get().hasWordmark {
                    var value = registers.a.get() | 0b10000000
                    if !value.parityCheck {
                        value.setCheckBit()
                    }
                    coreStorage.set(at: addr, with: value)
                }
                
                // Decrease B-Addr-Reg
                addr = registers.addrB.intValue
                addr -= 1
                registers.addrB = addr.addressValue
                
                // FIXME: Implement parity and validity checks...
                
                // End E-Phase
                end = true
            } else {
                // Decrease B-Addr-Reg
                addr = registers.addrB.intValue
                addr -= 1
                registers.addrB = addr.addressValue
                
                // FIXME: Implement parity and validity checks...
            }
        } while !end
    }
}


/// Move digit instruction
extension ProcessingUnit {
    internal func op_move_digit_zone() throws {
        // Run general A-Cycle
        generalEPhaseCycleA()
        
        // B-Cycle
        
        // B-Addr-Reg to STAR
        registers.addrS = registers.addrB
        
        // Read storage into B-Reg
        var addr = registers.addrS.intValue
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
        if !value.parityCheck {
            value.setCheckBit()
        }
        
        // Write new value to storage
        coreStorage.set(at: addr, with: value)
        
        // Decrease B-Addr-Reg
        addr = registers.addrB.intValue
        addr -= 1
        registers.addrB = addr.addressValue
        
        // FIXME: Implement parity and validity checks...
    }
}


/// Load instruction
extension ProcessingUnit {
    internal func op_load() throws {
        var quit = false
        
        repeat {
            // Run general A-Cycle
            generalEPhaseCycleA()
            
            // B-Cycle
            
            // B-Addr-Reg to STAR
            registers.addrS = registers.addrB
            
            // Read storage to B-Reg
            var addr = registers.addrS.intValue
            registers.b.set(with: coreStorage.get(from: addr))

            // Decrease B-Addr-Reg
            addr = registers.addrB.intValue
            addr -= 1
            registers.addrB = addr.addressValue

            // A-Reg char and WM to storage
            coreStorage.set(at: addr, with: registers.a.get() & 0b10111111)
            
            // FIXME: Implement parity and validity checks...
            
            // Check for WM in A-Reg
            quit = registers.a.get().hasWordmark
        } while !quit
    }
}


/// No operation instruction
extension ProcessingUnit {
    internal func op_noop() throws {
        return
    }
}


extension ProcessingUnit {
    func op_print() {
        let filename = "printer.out.txt"
        let bytes = coreStorage.getPrintStorage()
        if let message = Lib1401.CharacterEncodings.shared.decode(words: bytes) {
            Logger.debug("PRINTER DATA: \(message.count) bytes")
            Logger.info("PRINTER OUT: \(message)")

            do {
                var body = ""
                if let url = URL(string: "file://\(FileManager.default.currentDirectoryPath)/\(filename)"),
                    let data = try? String(contentsOf: url) {
                    body = data
                }

                try "\(body)\(message)\n".write(toFile: "./\(filename)", atomically: false, encoding: .utf8)
                Logger.info("PRINTER WRITTEN: \(filename): \(message.count+1) bytes")
            } catch {
                Logger.error("ERROR WRITING PRINT OUT: \(error.localizedDescription)")
            }
        }
    }
}

