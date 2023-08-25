# IBM 1401 Emulator in Swift

This project is some very **early** and **inclomplete** version of an IBM 1401 emulator written in Swift.

While studying the machine and finishing a simple hello world punch card code, it was hard for me to test my code as there are not many emulators for the machine and I was not able to make simh run at this time.

With the help of the amazing emulator of [https://rolffson.de](https://rolffson.de) I was finally able to punch and run my code virtually on his software. Unfortunately, the project is only availble for Microsoft Windows and more a 3D simulation than a convinient emulator, so I descided to write my own...

| **⚠️ The whole emulator is incomplete. For now, not all opcodes are implemented and reading external files into the storage is not finished.** |
| -------- |

<img src="https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg" width="400">

*> Image: [https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg](https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg)*

More information about the machine itself: [http://ibm-1401.info](http://ibm-1401.info)

## Requirements

The code should run on any system that supports Swift 3.7 and higher.

The emulator depends on [lib1401](https://github.com/sanzaru/lib1401)

## Manual

### Usage

Inside the project directory run: ```swift run```

to start an emulator. You will be welcomed with a prompt where you can enter commands.

### Emulator commands

#### Load program (l / load)

You can load external files with punch card code when providing an **absolute** path to the load command.

**Example:** ```l /some/absolute/path/to/a/file.cd```

Without any file name a default hello world program will be loaded.

#### Start / Step (s / start)

This command emulates pressing the IBM 1401 start button in single step mode.

#### Run (r / run)

This command emulates pressing the IBM 1401 start button in run mode.

#### Dump storage (d / dump)

This command dumps the complete storage. Note that the output is in BCD mode.

#### Monitor (m / monitor)

This command dumps all registers and contents.

#### Reset (rst / reset)

Terminate execution cycle, reset core storage and registers. This command allows you to load and run another program.

#### Quit (q / quit)

Quit the emulator


## Features

- [x] Load arbitrary program from external file
- [ ] Parity and validity checks for registers
- [ ] Normal 1401 opcodes:
    - [x] Set Word Mark (,)
    - [x] Clear Storage (/)
    - [x] Move (M)
    - [x] Move Digit (D)
    - [x] Move Zone (Y)
    - [x] Halt (.)
    - [ ] Halt and branch (.)
    - [x] No Operation (N)
    - [x] No Operation (L)
    - [ ] Write a line (2) - **Partially implemented**
    - [ ] Clear word mark ())
    - [ ] Divide (()
    - [ ] Modify address (=)
    - [ ] Zero and add (&)
    - [ ] Add (A)
    - [ ] Branch or branch on indicator (B)
    - [ ] Compare (C)
    - [ ] Move numerical / digit (D)
    - [ ] Move characters and edit (E)
    - [ ] _UNDOCUMENTED / UNCLEAR_ (G)
    - [ ] Zero and substract (-)
    - [ ] Load characters to word mark (L)
    - [ ] Move characters to word mark (M)
    - [ ] Move characters to record or group (P)
    - [ ] Subtract (S)
    - [ ] Branch if word mark and/or zone (V)
    - [ ] Move characters and supress zeros (Z)
    - [x] Read a card (1)
    - [ ] Read a card and branch (1)
    - [ ] Write and read (3)
    - [ ] Punch a card (4)
    - [ ] Read and punch (5)
    - [ ] Write and punch (6)
    - [ ] Write, read and punch (7)

- [ ] **Optioal opcodes:**
    - [ ] Multiply ( )
    - [ ] Store B-Address register (H)
    - [ ] Store A-Address register (Q)
    - [ ] Branch if bit equal (W)
    - [ ] Move and insert zeros (X)
    - [ ] Start read feed (8)
    - [ ] Start punch feed (9)

- [ ] **Tape:**
    - [ ] Control unit (U)

- [ ] **Printer:**
    - [ ] Control carriage (F)

- [ ] **Bits:**
    - [ ] Move zone (Z)

  - [ ] **Special:**
    - [ ] Select stacker and other device controls (K)

  - [ ] **1460-Features:**
    - [ ] Translate (T)
