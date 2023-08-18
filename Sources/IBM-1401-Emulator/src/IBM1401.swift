
//
// Bit positions are: WM | C | B | A | 8 | 4 | 2 | 1
//

import Foundation
import Lib1401

extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { Int(String($0)) }
    }
}


struct MonitorData {
    var registerA: Word
    var registerB: Word
    var registerI: Word
    var registerAddrA: Address
    var registerAddrB: Address
    var registerAddrI: Address
    var registerAddrS: Address
    var instructionCounter: Int
}


final class IBM1401 {
    var monitorData: MonitorData {
        pu.monitorData
    }

    private let pu: ProcessingUnit
    
    private var cycles: Int = 0
    private var lastCycles = 0
    private var running: Bool
    
    init(storageSize: ProcessingUnit.CoreStorage.StorageSize = .k1) {
        running = false
                
        pu = ProcessingUnit(storageSize: storageSize)        
    }
    
    func CyclesPerSecond() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            if self.running {
                #if DEBUG
                    let diff = self.cycles - self.lastCycles
                    //print("\u{001B}[2J")
                    print("CPS: \(diff)")
                    print("\tShould:\t86957")
                    print("\tDiff:\t\(diff - 86957) / Factor: \(diff / 86957)\n\n")
                #endif
                
                self.lastCycles = self.cycles
            }
            
            self.CyclesPerSecond()
        }
    }
    
    func load(code: String) -> Int {
        let encoded = Lib1401.CharacterEncodings.shared.encode(code: code)

        if encoded.count <= pu.coreStorage.count {
            for i in 0..<encoded.count {
                pu.coreStorage.set(at: i, with: encoded[i])
            }
            
            // Set word mark in first storage address
            pu.coreStorage.setWordMark(at: 0)
        }
        
        return encoded.count
    }
    
    func dumpStorage() {
        let breakPoint = 20
        
        func leading(index: Int) {
            print(String(format: "%03d ", row*breakPoint+1), terminator: "")
        }
        
        (1...breakPoint).forEach {
            if $0 == 1 {
                print(String(format: "    %03d", $0), terminator: " ")
            } else {
                print(String(format: "%03d", $0), terminator: " ")
            }
        }
        print("")

        (1...breakPoint).forEach {
            if $0 == 1 {
                print("    ====", terminator: "")
            } else {
                print("====", terminator: "")
            }
        }
        print("")
        
        var row = 0
        leading(index: 0)
        
        (0..<pu.coreStorage.count).forEach {
            let v = String(format: "%03d", pu.coreStorage.get(from: $0, setZero: false))
            
            if $0 > 0 && $0 % breakPoint == 0 {
                print("")
                row += 1
                
                if $0 > 0 && $0 % 100 == 0 {
                    print("")
                }
                
                leading(index: (row*breakPoint))
            }
                        
            print(v, terminator: $0 == pu.coreStorage.count-1 ? "" : ",")
        }
    }
    
    func start() throws {
        try pu.step()        
    }
    
    func run() {
        #if DEBUG
            print("IBM 1401 running...")
        #endif
        
        self.CyclesPerSecond()
        self.running.toggle()
        
        while self.running {
            //print("Ticks: \(ticks)")
            cycles += 1
        }

    }
}
