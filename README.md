# IBM-1401 Emulator in Swift 

This project is some **early** and inclomplete version of an IBM-1401 emulator written in vanilla Swift without any external libraries. 

While studying the machine and finishing a simple hello world punch card code, it was hard for me to test my code as there are not many emulators for the machine. With the help of the amazing emulator of [https://rolffson.de](https://rolffson.de) I was finally able to punch and run my code virtually on his emulator. Unfortunately, the project is only availble for windows and so I descided to write my own emulator...

| **⚠️ The whole emulator is quite incomplete. For now, not all opcodes are implemented and the emulator lacks of printer support or reading external files into the storage.** |
| -------- |

<img src="https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg" width="400">

*> Image: [https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg](https://upload.wikimedia.org/wikipedia/commons/c/cb/BRL61-IBM_1401.jpg)*

More information about the machine itself: [http://ibm-1401.info](http://ibm-1401.info)

## Requirements

The code should run on any system that supports Swift 3.x. No external library or packages are required.

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


### Implemented Opcodes

| Operation | ASCII character |
| ----------- | ------------------ |
| Set Word Mark |  , |
| Clear Storage |  / |
| Move | M |
| Move Digit | D |
| Move Zone | Y |
| Halt | . |
| No Operation | N |
| Load | L |
