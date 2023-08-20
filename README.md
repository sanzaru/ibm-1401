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

## Features

- [ ] Load arbitrary program from external file
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
    - [ ] Read a card (1)
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

## Manual

### Emulator commands

| Command | Description |
| ------- | ----------- |
| l | Load program into storage |
| d | Dump storage |
| s | Step |
| r | Run loaded program |
| m | Monitor |
| q | Quit emulator |
