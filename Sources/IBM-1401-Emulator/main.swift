import Foundation

// DEBUG hello world program
let HelloWorld = ",008015,201022,029036,043047,051055,062063,067/332/299M0772112.047HELLO WORLD"
//let HelloWorld = ",008015.000"

class IBM1401App {
    static let shared = IBM1401App()

    private let ibm1401 = IBM1401(storageSize: .k1)

    private var quit: Bool = false
    private var prompt: String {
        print("\n1401>", terminator: " ")
        let cmd = readLine(strippingNewline: true)

        return cmd?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .nonBaseCharacters) ?? ""
    }

    func run() {
        print("\n=========== IBM 1401 emulator ===========")

        while !quit {
            parseCommand(from: prompt)
        }
    }

    private func stopCondition(message: String) {
        dump("STOP CONDITION CATCHED: \(message)")
    }

    private func parseCommand(from: String) {
        let arguments = from.split(separator: " ").map({ String($0) })
        let command = arguments[0]

        switch command {
        case "quit", "q":
            quit = true
            print("Goodbye!")

        case "load", "l":
            var loaded = 0
            do {
                if arguments.count >= 2 {
                    let filename = "file://" + arguments[1]

                    if let url = URL(string: filename) {
                        print("Loading file: \(filename)")
                        let data = try Data(contentsOf: url)
                        if let code = String(data: data, encoding: .utf8) {
                            loaded = ibm1401.load(code: code)
                        }
                    }
                } else {
                    print("DEFAULT SET")
                    loaded = ibm1401.load(code: HelloWorld)
                }
            } catch {
                print(error.localizedDescription)
            }

            print("Loaded \(loaded) words")
            //print("Loaded \(ibm1401.load(code: dummyProg)) words")

        case "dump", "d":
            print("\nCore storage:")
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
                    print("SYSTEM HALT")
                    quit = true
                } catch {
                    quit = true
                    fatalError(error.localizedDescription)
                }
            }

        case "monitor", "m":
            let data = ibm1401.monitorData

            print("Monitor")
            print("=========")

            print("Intruction Length: \(data.instructionCounter)")
            print("")

            print("Registers:")
            print("""
                \tA: \(data.registerA) (\(data.registerA.binaryString))
                \tB: \(data.registerB) (\(data.registerB.binaryString))
                \tI: \(data.registerI) (\(data.registerI.binaryString))\n
            """)
            print("")

            print("Address registers:")
            print("""
                \tA: \(data.registerAddrA)
                \tB: \(data.registerAddrB)
                \tI: \(data.registerAddrI)
                \tS: \(data.registerAddrS)
            """)

        /*case "run", "r":
            print("Run...")
            ibm1401.run()*/

        default:
            print("Error: Unknown command \"\(command)\"")
            break
        }
    }
}

IBM1401App.shared.run()
