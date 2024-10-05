# IBM 1401 Emulator in Swift

This project is some very **early** and **incomplete** version of an IBM 1401 emulator written in Swift.

While studying the machine and finishing a simple hello world punch card code, it was hard for me to test my code as
there are not many emulators for the machine and I was not able to make simh run at this time.

With the help of the amazing emulator of [https://rolffson.de](https://rolffson.de) I was finally able to punch and run
my code virtually on his software. Unfortunately, the project is only available for Microsoft Windows and more a 3D
simulation than a convenient emulator, so I decided to write my own...

> [!IMPORTANT]
> The whole emulator is incomplete. For now, not all opcodes and almost no validity and parity checks are implemented, yet.

<img src="https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg" width="400">

*> Image: [https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg](https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg)*

More information about the machine itself: [http://ibm-1401.info](http://ibm-1401.info)

# Table of contents
- [IBM 1401 Emulator in Swift](#ibm-1401-emulator-in-swift)
- [Table of contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Manual](#manual)
    - [Emulator commands](#emulator-commands)
      - [Load program (l / load)](#load-program-l--load)
      - [Start / Step (s / start)](#start--step-s--start)
      - [Run (r / run)](#run-r--run)
      - [Dump storage (d / dump)](#dump-storage-d--dump)
      - [Monitor (m / monitor)](#monitor-m--monitor)
      - [Reset (rst / reset)](#reset-rst--reset)
      - [Quit (q / quit)](#quit-q--quit)
  - [Features](#features)


## Requirements

The code should run on any system that supports Swift 5.7 and higher.

The emulator depends on [lib1401](https://github.com/sanzaru/lib1401)

## Manual

Inside the project directory run: ```swift run``` to start the emulator.
You will be welcomed with a prompt where you can enter your commands.

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
    - [x] Halt and branch (.)
    - [x] No Operation (N)
    - [x] Load (L)
    - [x] Write a line (2) - **Partially implemented**
    - [x] Clear word mark ())
    - [ ] Divide (()
    - [ ] Modify address (=)
    - [ ] Zero and add (&)
    - [ ] Add (A)
    - [x] Branch or branch on indicator (B)
    - [ ] Compare (C)
    - [ ] Move numerical / digit (D)
    - [ ] Move characters and edit (E)
    - [ ] _UNDOCUMENTED / UNCLEAR_ (G)
    - [ ] Zero and subtract (-)
    - [ ] Move characters to record or group (P)
    - [ ] Subtract (S)
    - [ ] Branch if word mark and/or zone (V)
    - [ ] Move characters and suppress zeros (Z)
    - [x] Read a card (1)
    - [x] Read a card and branch (1)
    - [ ] Write and read (3)
    - [ ] Punch a card (4)
    - [ ] Read and punch (5)
    - [ ] Write and punch (6)
    - [ ] Write, read and punch (7)

- [ ] **Optional opcodes:**
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
