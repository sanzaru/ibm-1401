import Foundation


// DEBUG hello world program
//let HelloWorld = ",008015,201022,029036,043047,051055,062063,067/332/299M0772112.047HELLO WORLD"
let HelloWorld = ",008015,201022,029036,043047,051055,062063,067/332/299L0772112.047HELLO WORLD"
//let HelloWorld = ",008015.000"

func prompt() -> String {
    print("\n1401>", terminator: " ")
    let cmd = readLine(strippingNewline: true)
    
    return cmd?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .nonBaseCharacters) ?? ""
}

func stopCondition(message: String) {
    dump("STOP CONDITION CATCHED: \(message)")
}


func parseCommand(command: String) {
    switch command {
    case "quit", "q":
        quit = true
        print("Goodbye!")
        
    case "load", "l":
        print("Loaded \(ibm1401.load(code: HelloWorld)) words")
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
        let data = ibm1401.monitorData()
        
        print("Monitor")
        print("=========")
        
        print("Intruction Length: \(data.instructionCounter)")
        print("")
        
        print("Registers:")
        print("""
            \tA: \(data.registerA) (\(data.registerA.binaryString()))
            \tB: \(data.registerB) (\(data.registerB.binaryString()))
            \tI: \(data.registerI) (\(data.registerI.binaryString()))\n
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


/// Start the main loop
var quit: Bool = false
let ibm1401 = IBM1401(storageSize: .k1)

print("\n=========== IBM 1401 emulator ===========")

while !quit {
    parseCommand(command: prompt())
}
