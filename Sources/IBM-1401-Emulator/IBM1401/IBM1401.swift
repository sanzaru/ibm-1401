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

//
// Bit positions are: WM | C | B | A | 8 | 4 | 2 | 1
//

import Foundation

final class IBM1401 {
    var monitorData: Monitor.Data {
        pu.monitorData
    }

    private let pu: ProcessingUnit
    private let cardReader = IBM1402()

    private var cycles: Int = 0
    private var lastCycles = 0
    private var running: Bool

    init(storageSize: ProcessingUnit.CoreStorage.StorageSize = .k1) {
        running = false

        pu = ProcessingUnit(storageSize: storageSize)
    }

//    func cyclesPerSecond() {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
//            if self.running {
//                #if DEBUG
//                let diff = self.cycles - self.lastCycles
//                Logger.debug("CPS: \(diff)")
//                Logger.debug("\tShould:\t86957")
//                Logger.debug("\tDiff:\t\(diff - 86957) / Factor: \(diff / 86957)\n\n")
//                #endif
//                
//                self.lastCycles = self.cycles
//            }
//            
//            self.cyclesPerSecond()
//        }
//    }

    func load(code: String) throws {
        if let loadedCard = try cardReader.load(from: code) {
            load(bytes: loadedCard)
        }
    }

    func load(bytes: [Word]) {
        var index = 0
        bytes.forEach { byte in
            pu.coreStorage.set(at: index, with: byte)
            index += 1
        }

        Logger.debug("Loaded \(bytes.count) bytes")

        pu.coreStorage.setWordMark(at: 0)
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

    func readCard() {
        guard let card = cardReader.read() else {
            Logger.fatal("Cannot read card!")
            return
        }

        pu.registers = .init()
        load(bytes: card)
    }

//    func run() {
//        Logger.debug("IBM 1401 running...")
//        
//        self.CyclesPerSecond()
//        self.running.toggle()
//        
//        while self.running {
//            //print("Ticks: \(ticks)")
//            cycles += 1
//        }
//
//    }

    func reset() {
        pu.stopExecutionPhase()
        pu.registers = .init()
        pu.coreStorage.reset()
    }
}
