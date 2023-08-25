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

import Foundation

// DEBUG hello world program
enum DefaultProgramCards: String {
    case helloWorld = ",008015,201022,029036,043047,051055,062063,067/332/299M0772112.047HELLO WORLD"
}

struct IBM1401App {
    static var shared = IBM1401App()

    private let ibm1401 = IBM1401(storageSize: .k1)

    private var quit: Bool = false
    private var prompt: String {
        print("\n1401>", terminator: " ")
        let cmd = readLine(strippingNewline: true)

        return cmd?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .nonBaseCharacters) ?? ""
    }

    mutating func run() {
        print("\n=========== IBM 1401 emulator ===========")

        while !quit {
            parseCommand(from: prompt)
        }
    }

    private func stopCondition(message: String) {
        Logger.info("STOP CONDITION CATCHED: \(message)")
    }

    private mutating func parseCommand(from: String) {
        let arguments = from.split(separator: " ").map({ String($0) })
        let command = arguments[0]

        switch command {
        case "quit", "q":
            quit = true
            print("Goodbye!")

        case "load", "l":
            do {
                if arguments.count >= 2 {
                    let filename = "file://" + arguments[1]

                    if let url = URL(string: filename) {
                        Logger.info("Loading file: \(filename)")
                        let data = try Data(contentsOf: url)
                        if let code = String(data: data, encoding: .utf8) {
                            try ibm1401.load(code: code)
                        }
                    }
                } else {
                    Logger.info("DEFAULT SET")
                    try ibm1401.load(code: DefaultProgramCards.helloWorld.rawValue)
                }
            } catch {
                Logger.error(error.localizedDescription)
            }

        case "dump", "d":
            Logger.info("\nCore storage:")
            ibm1401.dumpStorage()

        case "start", "s":
            do {
                try ibm1401.start()
            } catch ProcessingUnit.Exceptions.stopCondition(let message) {
                stopCondition(message: message)
            } catch {
                fatalError(error.localizedDescription)
            }

        case "run", "r":
            var quit = false
            while !quit {
                do {
                    try ibm1401.start()
                    // 87KHz
                } catch ProcessingUnit.Exceptions.stopCondition(let message) {
                    stopCondition(message: message)
                    quit = true
                } catch ProcessingUnit.Exceptions.haltSystem {
                    Logger.info("SYSTEM HALT")
                    quit = true
                } catch ProcessingUnit.Exceptions.readCard {
                    ibm1401.readCard()
                } catch {
                    quit = true
                    fatalError(error.localizedDescription)
                }
            }

        case "monitor", "m":
            Monitor.dump(data: ibm1401.monitorData)

        case "reset", "rst":
            ibm1401.reset()
            Logger.info("System reset")

        default:
            print("Error: Unknown command \"\(command)\"")
            break
        }
    }
}

IBM1401App.shared.run()
