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
        case readCard
    }

    internal enum ExecutionMode {
        case addressStop, singleCycleProcess, characterDisplay, alter, run,
             iex, storagePrintOut, singleCycleNonProcess, storageScan
    }

    internal struct Registers {
        var a = Register()
        var b = Register()
        var i = Register()
        var addrA: Address = [74, 74, 74] // 0, 0, 0 BCD encoded
        var addrB: Address = [74, 74, 74]
        var addrI: Address = [74, 74, 74]
        var addrS: Address = [74, 74, 74] // STAR
    }

    internal var cyclePhase: CyclePhase = .iPhase
    internal var registers = Registers()
    internal var iAddrRegBlocked: Bool = false

    private var ePhaseACycleEliminate: Bool = false
    private var instructionFromRegisterA: Bool = false

    init(storageSize: ProcessingUnit.CoreStorage.StorageSize = .k1) {
        coreStorage = ProcessingUnit.CoreStorage(size: storageSize)
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
            Logger.debug("ADDR I-OP: \(addr) : \(registers.addrI)")
            Logger.debug("I-IO REG: \(iAddrRegBlocked ? "Blocked" : "Open")")

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
            registers.i.set(with: (registers.b.get() & 0b01111111))

            Logger.debug("I-OP Instruction: \(registers.i):\(registers.i.get().char ?? Character(""))")

        case 1, 2:
            let addr = cycleIStart()
            Logger.debug("ADDR I-\(iPhaseCount == 1 ? "1" : "2"): \(addr) : \(registers.addrI.encodedArray)")

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
            Logger.debug("ADDR I-3: \(addr) : \(registers.addrI.encodedArray)")

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
            Logger.debug("ADDR I-4: \(addr) : \(registers.addrI.encodedArray)")

            // Check for branch opcode
            if (registers.i.get().isOpCode(code: "B") && (registers.b.get().isBlank || registers.b.get().hasWordmark) ) {
                // TODO: Implement branch instruction handling
                return
            }

            // Check WM in B-Register
            if registers.b.get().hasWordmark {
                // FIXME: Implement op code handling
                Logger.debug("WORD MARK IS SET: \(registers.b.get())")

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
                registers.addrB[$0] = Lib1401.CharacterEncodings.shared.simh[" "]!
            }

            registers.addrB[0] = registers.b.get()

        case 5:
            let addr = cycleIStart()
            Logger.debug("ADDR I-5: \(addr) : \(registers.addrI.encodedArray)")

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
            Logger.debug("ADDR I-6: \(addr) : \(registers.addrI.encodedArray)")

            registers.a.set(with: registers.b.get())
            registers.addrB[2] = registers.b.get()

        case 7:
            let addr = cycleIStart()
            Logger.debug("ADDR I-7: \(addr) : \(registers.addrI.encodedArray)")

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
        Logger.debug("ADDR I-8: \(addr) : \(registers.addrI.encodedArray)")

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
        let opcode = registers.i.get()

        Logger.debug("E-PHASE: \(opcode.char ?? Character(""))")

        if opcode.isOpCode(code: Opcodes.setWordMark.rawValue) {
            op_setWordmark()
        }

        else if opcode.isOpCode(code: Opcodes.clearStorage.rawValue) {
            try op_clearStorage()
            ePhaseACycleEliminate = false
            iAddrRegBlocked = false
        }

        else if opcode.isOpCode(code: Opcodes.move.rawValue) {
            try op_move()
        }

        else if opcode.isOpCode(code: Opcodes.moveDigit.rawValue) || opcode.isOpCode(code: Opcodes.moveZone.rawValue) {
            try op_move_digit_zone()
        }

        else if opcode.isOpCode(code: Opcodes.load.rawValue) {
            try op_load()
        }

        else if opcode.isOpCode(code: Opcodes.halt.rawValue) {
            try op_halt()
        }

        else if opcode.isOpCode(code: Opcodes.print.rawValue) {
            op_print()
        }

        else if opcode.isOpCode(code: Opcodes.readCard.rawValue) {
            stopExecutionPhase()
            throw Exceptions.readCard
        }

        else {
            throw Exceptions.stopCondition("E-PHASE ERROR: INSRUCTION NOT IMPLEMENTED OR UNKNOWN: \(opcode.char ?? Character(""))")
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
