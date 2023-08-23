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
import Lib1401

final class IBM1401 {
    var monitorData: MonitorData {
        pu.monitorData
    }

    private let pu: ProcessingUnit
    private let cardReader: IBM1402

    private var cycles: Int = 0
    private var lastCycles = 0
    private var running: Bool
    private var cardStack: [String] = []

    init(storageSize: ProcessingUnit.CoreStorage.StorageSize = .k1) {
        running = false
                
        pu = ProcessingUnit(storageSize: storageSize)        
        cardReader = .init()
    }
    
    func CyclesPerSecond() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            if self.running {
                #if DEBUG
                let diff = self.cycles - self.lastCycles
                Logger.debug("CPS: \(diff)")
                Logger.debug("\tShould:\t86957")
                Logger.debug("\tDiff:\t\(diff - 86957) / Factor: \(diff / 86957)\n\n")
                #endif
                
                self.lastCycles = self.cycles
            }
            
            self.CyclesPerSecond()
        }
    }

    func load(code: String) throws -> Int {
        let encoded = try Lib1401.CharacterEncodings.shared.encode(code: code)

        let loadedCard = cardReader.load(from: encoded)

        var index = 0
        loadedCard.forEach { card in
            pu.coreStorage.set(at: index, with: encoded[index])
            index += 1
        }

        pu.coreStorage.setWordMark(at: 0)

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
        Logger.debug("IBM 1401 running...")
        
        self.CyclesPerSecond()
        self.running.toggle()
        
        while self.running {
            //print("Ticks: \(ticks)")
            cycles += 1
        }

    }
}
