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

struct Monitor {
    struct Data {
        var registerA: Word
        var registerB: Word
        var registerI: Word
        var registerAddrA: Address
        var registerAddrB: Address
        var registerAddrI: Address
        var registerAddrS: Address
        var instructionCounter: Int
    }

    static func dump(data: Monitor.Data) {
        print("Monitor")
        print("=========")

        print("Intruction Length: \(data.instructionCounter)")
        print("")

        print("Registers:")
        print("""
            \tA: \(data.registerA) (\(data.registerA.binaryString)) [\(data.registerA.char ?? Character(""))]
            \tB: \(data.registerB) (\(data.registerB.binaryString)) [\(data.registerB.char ?? Character(""))]
            \tI: \(data.registerI) (\(data.registerI.binaryString)) [\(data.registerI.char ?? Character(""))]\n
        """)
        print("")

        print("Address registers:")
        print("""
            \tA: \(data.registerAddrA)
            \tB: \(data.registerAddrB)
            \tI: \(data.registerAddrI)
            \tS: \(data.registerAddrS)
        """)
    }
}
