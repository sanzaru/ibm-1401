//
//  File.swift
//  
//
//  Created by Martin Albrecht on 25.05.20.
//


//
// Bit positions are: WM | C | B | A | 8 | 4 | 2 | 1
//

import Foundation

extension BinaryInteger {
    var digits: [Int] {
        return String(describing: self).compactMap { Int(String($0)) }
    }
}


struct MonitorData {
    var registerA: Word
    var registerB: Word
    var registerI: Word
    var registerAddrA: [Word]
    var registerAddrB: [Word]
    var registerAddrI: [Word]
    var registerAddrS: [Word]
    var instructionCounter: Int
}


final class IBM1401 {
    private let pu: ProcessingUnit
    
    private var cycles: Int = 0
    private var lastCycles = 0
    private var running: Bool
    
    init(storageSize: CoreStorage.StorageSize = .k1) {
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
        let encoded = encode(ascii: code)
        
        if encoded.count <= 80 {
            for i in 0..<encoded.count {
                pu.coreStorage.set(at: i, with: encoded[i])
            }
            
            // Set word mark in first storage address
            pu.coreStorage.setWordMark(at: 0)
        }
        
        return encoded.count
    }
    
    func monitorData() -> MonitorData {
        pu.monitorData()
    }
    
    func dumpStorage() {
        let breakPoint = 20
        
        func leading(index: Int) {
            print(String(format: "%03d ", row), terminator: "")
        }
        
        for i in 1...breakPoint {
            if i == 1 {
                print(String(format: "    %03d", i), terminator: " ")
            } else {
                print(String(format: "%03d", i), terminator: " ")
            }
        }
        print("")
        
        for i in 1...breakPoint {
            if i == 1 {
                print("    ====", terminator: "")
            } else {
                print("====", terminator: "")
            }
        }
        print("")
        
        var row = 0
        leading(index: 0)
        
        for i in 0..<pu.coreStorage.count() {
            let v = String(format: "%03d", pu.coreStorage.get(from: i, setZero: false))
            
            if i > 0 && i % breakPoint == 0 {
                print("")
                row += 1
                
                if i > 0 && i % 100 == 0 {
                    print("")
                }
                
                leading(index: (row*breakPoint))
            }
                        
            print(v, terminator: i == pu.coreStorage.count()-1 ? "" : ",")
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
    
    
    // MARK: - Private
    
    private func encode(ascii: String) -> [Word] {
        return ascii.uppercased().map { CharacterEncodings[$0]! }
    }
}
