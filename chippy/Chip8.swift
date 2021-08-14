//
//  Chip8.swift
//  chippy
//
//  Created by Adam Campbell on 7/18/21.
//

import Foundation

let STACK_SIZE = 16
let RAM_SIZE = 4096
let REGISTER_SIZE = 16

class Chip8 : ObservableObject {
    var registers = [UInt8](repeatElement(0x0, count: REGISTER_SIZE))
    var I: UInt16 = 0x00
    var PC: UInt16 = 0x00
    var SP: UInt8 = 0x0
    var ram: [UInt8] = [UInt8](repeatElement(0x00, count: RAM_SIZE))
    var stack: [UInt16] = [UInt16](repeatElement(0x0000, count: STACK_SIZE))
    var asdf2 = ""
    
    let font: [UInt8] = [ 0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
                          0x20, 0x60, 0x20, 0x20, 0x70, // 1
                          0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
                          0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
                          0x90, 0x90, 0xF0, 0x10, 0x10, // 4
                          0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
                          0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
                          0xF0, 0x10, 0x20, 0x40, 0x40, // 7
                          0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
                          0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
                          0xF0, 0x90, 0xF0, 0x90, 0x90, // A
                          0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
                          0xF0, 0x80, 0x80, 0x80, 0xF0, // C
                          0xE0, 0x90, 0x90, 0x90, 0xE0, // D
                          0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
                          0xF0, 0x80, 0xF0, 0x80, 0x80] // F

    
    init() {
        ram.replaceSubrange(0x0..<font.count, with: font)
    }
    
    func loadRom(rom: [UInt8]) {
        ram.replaceSubrange(0x200..<rom.count+0x200, with: rom)
        PC = 0x200
    }
    
    var display: Display = Display(pixelsWide: 64, pixelsHigh: 32)
    
    let functions : [Opcode : (Opcode, inout Chip8) -> Void] =
        [Opcode(first: 0x0, second: 0x0, third: 0xE, fourth: 0x0): CLS,
         Opcode(first: 0x0, second: 0x0, third: 0xE, fourth: 0xE): RTS,
         Opcode(first: 0x1, second: nil, third: nil, fourth: nil): JUMP,
         Opcode(first: 0x2, second: nil, third: nil, fourth: nil): CALL,
         Opcode(first: 0x3, second: nil, third: nil, fourth: nil): SKE,
         Opcode(first: 0x4, second: nil, third: nil, fourth: nil): SKNE,
         Opcode(first: 0x5, second: nil, third: nil, fourth: 0x0): SKRE,
         Opcode(first: 0x6, second: nil, third: nil, fourth: nil): LOAD,
         Opcode(first: 0x7, second: nil, third: nil, fourth: nil): ADD,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x0): MOVE,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x1): OR,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x2): AND,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x3): XOR,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x4): ADDR,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x5): SUB,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x6): SHR,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0x7): SUBN,
         Opcode(first: 0x8, second: nil, third: nil, fourth: 0xE): SHL,
         Opcode(first: 0x9, second: nil, third: nil, fourth: 0x0): SKRNE,
         Opcode(first: 0xA, second: nil, third: nil, fourth: nil): LOADI,
         Opcode(first: 0xB, second: nil, third: nil, fourth: nil): JUMPI,
         Opcode(first: 0xC, second: nil, third: nil, fourth: nil): RAND,
         Opcode(first: 0xD, second: nil, third: nil, fourth: nil): DRAW,
         Opcode(first: 0xE, second: nil, third: 0x9, fourth: 0xE): SKPR,
         Opcode(first: 0xE, second: nil, third: 0xA, fourth: 0x1): SKUP,
         Opcode(first: 0xF, second: nil, third: 0x0, fourth: 0x7): MOVED,
         Opcode(first: 0xF, second: nil, third: 0x0, fourth: 0xA): KEYD,
         Opcode(first: 0xF, second: nil, third: 0x1, fourth: 0x5): LOADD,
         Opcode(first: 0xF, second: nil, third: 0x1, fourth: 0x8): LOADS,
         Opcode(first: 0xF, second: nil, third: 0x1, fourth: 0xE): ADDI,
         Opcode(first: 0xF, second: nil, third: 0x2, fourth: 0x9): LDSPR,
         Opcode(first: 0xF, second: nil, third: 0x3, fourth: 0x3): BCD,
         Opcode(first: 0xF, second: nil, third: 0x5, fourth: 0x5): STOR,
         Opcode(first: 0xF, second: nil, third: 0x6, fourth: 0x5): READ]
}


/// Clears the screen
/// - Parameters:
///   - opcode: 0x00E0
///   - chip: chip8 instance to operate on
func CLS(opcode: Opcode, chip: inout Chip8) {
    chip.display.Clear()
}

/// Returns from a subroutine.
/// - Parameters:
///   - opcode: 0x00EE
///   - chip: chip8 instance to operate on
func RTS(opcode: Opcode, chip: inout Chip8) {
    chip.PC = chip.stack[Int(chip.SP)]
    chip.SP = chip.SP - 1
}

/// Jump to location nnn.
/// The interpreter sets the program counter to nnn.
/// - Parameter operation: 1nnn - JP addr
func JUMP(opcode: Opcode, chip: inout Chip8) {
    guard let address = opcode.GetNNN()
    else {
        print("Error - Function: \(#function), line: \(#line)")
        return
    }
    
    chip.PC = address
}

/// Call subroutine at nnn.
/// The interpreter increments the stack pointer, then puts the current PC on the top of the stack. The PC is then set to nnn.
/// - Parameter operation: 2nnn - CALL addr
func CALL(opcode: Opcode, chip: inout Chip8) {
    print("Function: \(#function), line: \(#line)")
}

/// Skip next instruction if Vx = kk.
/// The interpreter compares register Vx to kk, and if they are equal, increments the program counter by 2.
/// - Parameter operation: 3xkk - SE Vx, byte
func SKE(opcode: Opcode, chip: inout Chip8) {
    
}

/// Skip next instruction if Vx != kk.
/// The interpreter compares register Vx to kk, and if they are not equal, increments the program counter by 2.
/// - Parameter operation: 4xkk - SNE Vx, byte
func SKNE(opcode: Opcode, chip: inout Chip8) {
    
}

/// Skip next instruction if Vx = Vy.
/// The interpreter compares register Vx to register Vy, and if they are equal, increments the program counter by 2.
/// - Parameter operation: 5xy0 - SE Vx, Vy
func SKRE(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = kk.
/// The interpreter puts the value kk into register Vx.
/// - Parameter operation: 6xkk - LD Vx, byte
func LOAD(opcode: Opcode, chip: inout Chip8) {
    guard let value = opcode.GetNN(),
          let xIndex = opcode.GetX()
    else {
        print("Error - Function: \(#function), line: \(#line)")
        return
    }
    
    chip.registers[xIndex] = value
}

/// Set Vx = Vx + kk.
/// Adds the value kk to the value of register Vx, then stores the result in Vx.
/// - Parameter operation: 7xkk - ADD Vx, byte
func ADD(opcode: Opcode, chip: inout Chip8) {
    guard let value = opcode.GetNN(),
          let xIndex = opcode.GetX()
    else {
        print("Error - Function: \(#function), line: \(#line)")
        return
    }
    
    chip.registers[xIndex] += value
}

/// Set Vx = Vy.
/// Stores the value of register Vy in register Vx.
/// - Parameter operation: 8xy0 - LD Vx, Vy
func MOVE(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = Vx OR Vy.
/// Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx. A bitwise OR compares the corrseponding bits from two values, and if either bit is 1, then the same bit in the result is also 1. Otherwise, it is 0.
/// - Parameter operation: 8xy1 - OR Vx, Vy
func OR(opcode: Opcode, chip: inout Chip8) {
    print("Function: \(#function), line: \(#line)")
}


/// Set Vx = Vx AND Vy.
/// Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx. A bitwise AND compares the corrseponding bits from two values, and if both bits are 1, then the same bit in the result is also 1. Otherwise, it is 0.
/// - Parameter operation: 8xy2 - AND Vx, Vy
func AND(opcode: Opcode, chip: inout Chip8) {
    print("Function: \(#function), line: \(#line)")
}

/// Set Vx = Vx XOR Vy.
/// Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx. An exclusive OR compares the corrseponding bits from two values, and if the bits are not both the same, then the corresponding bit in the result is set to 1. Otherwise, it is 0.
/// - Parameter operation: 8xy3 - XOR Vx, Vy
func XOR(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = Vx + Vy, set VF = carry.
/// The values of Vx and Vy are added together. If the result is greater than 8 bits (i.e., > 255,) VF is set to 1, otherwise 0. Only the lowest 8 bits of the result are kept, and stored in Vx.
/// - Parameter operation: 8xy4 - ADD Vx, Vy
func ADDR (opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = Vx - Vy, set VF = NOT borrow.
/// If Vx > Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results stored in Vx.
/// - Parameter operation: 8xy5 - SUB Vx, Vy
func SUB(opcode: Opcode, chip: inout Chip8) {
    
}


/// Set Vx = Vx SHR 1.
/// If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
/// - Parameter operation: 8xy6 - SHR Vx {, Vy}
func SHR(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = Vy - Vx, set VF = NOT borrow.
/// If Vy > Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy, and the results stored in Vx.
/// - Parameter operation: 8xy7 - SUBN Vx, Vy
func SUBN(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = Vx SHL 1.
/// If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
/// - Parameter operation: 8xyE - SHL Vx {, Vy}
func SHL(opcode: Opcode, chip: inout Chip8) {
    
}

/// Skip next instruction if Vx != Vy.
/// The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
/// - Parameter operation: 9xy0 - SNE Vx, Vy
func SKRNE(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set I = nnn.
/// The value of register I is set to nnn.
/// - Parameter operation: Annn - LD I, addr
func LOADI(opcode: Opcode, chip: inout Chip8) {
    guard let address = opcode.GetNNN() else {
        print("Error - Function: \(#function), line: \(#line)")
        return
    }
    
    chip.I = address
}

/// Jump to location nnn + V0.
/// The program counter is set to nnn plus the value of V0.
/// - Parameter operation: Bnnn - JP V0, addr
func JUMPI(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = random byte AND kk.
/// The interpreter generates a random number from 0 to 255, which is then ANDed with the value kk. The results are stored in Vx. See instruction 8xy2 for more information on AND.
/// - Parameter operation: Cxkk - RND Vx, byte
func RAND(opcode: Opcode, chip: inout Chip8) {
    
}

/// Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
/// The interpreter reads n bytes from memory, starting at the address stored in I. These bytes are then displayed as sprites on screen at coordinates (Vx, Vy). Sprites are XORed onto the existing screen. If this causes any pixels to be erased, VF is set to 1, otherwise it is set to 0. If the sprite is positioned so part of it is outside the coordinates of the display, it wraps around to the opposite side of the screen.
/// - Parameter operation: Dxyn - DRW Vx, Vy, nibble
func DRAW(opcode: Opcode, chip: inout Chip8) {
    guard let xIndex = opcode.GetX(),
          let yIndex = opcode.GetY(),
          let mheight = opcode.GetN()
          else {
        print("Error - Function: \(#function), line: \(#line)")
        return
    }
    
    let opx = chip.registers[xIndex]
    let opy = chip.registers[yIndex]
    
    var myPixels: [Pixel] = [Pixel]()
    for yline in 0...(mheight-1) {
        for xline in 0...7 {
            let pixel = chip.ram[Int(chip.I)+Int(yline)]
            if ((pixel & (0x80 >> xline)) != 0)
            {
                myPixels.append(Pixel(offset: Int(opx)+Int(xline) + (Int(opy)+Int(yline))*64, color: .red))
            }
        }
    }
    
    // Clear the collision register
    chip.registers[0xF] = 0x0
    
    // if there was a collision in any of the pixels, the function will return true.
    // we need to flip the VF register accordingly
    if (chip.display.DrawPixels(pixels: myPixels)) {
        chip.registers[0xF] = 0x1
    }
}

/// Skip next instruction if key with the value of Vx is pressed.
/// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the down position, PC is increased by 2.
/// - Parameter operation: Ex9E - SKP Vx
func SKPR(opcode: Opcode, chip: inout Chip8) {
    
}

/// Skip next instruction if key with the value of Vx is not pressed.
/// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the up position, PC is increased by 2.
/// - Parameter operation: ExA1 - SKNP Vx
func SKUP(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set Vx = delay timer value.
/// The value of DT is placed into Vx.
/// - Parameter operation: Fx07 - LD Vx, DT
func MOVED(opcode: Opcode, chip: inout Chip8) {
    
}

/// Wait for a key press, store the value of the key in Vx.
/// All execution stops until a key is pressed, then the value of that key is stored in Vx.
/// - Parameter operation: Fx0A - LD Vx, K
func KEYD(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set delay timer = Vx.
/// DT is set equal to the value of Vx.
/// - Parameter operation: Fx15 - LD DT, Vx
func LOADD(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set sound timer = Vx.
/// ST is set equal to the value of Vx.
/// - Parameter operation: Fx18 - LD ST, Vx
func LOADS(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set I = I + Vx.
/// The values of I and Vx are added, and the results are stored in I.
/// - Parameter operation: Fx1E - ADD I, Vx
func ADDI(opcode: Opcode, chip: inout Chip8) {
    
}

/// Set I = location of sprite for digit Vx.
/// The value of I is set to the location for the hexadecimal sprite corresponding to the value of Vx.
/// - Parameter operation: Fx29 - LD F, Vx
func LDSPR(opcode: Opcode, chip: inout Chip8) {
    
}

/// Store BCD representation of Vx in memory locations I, I+1, and I+2.
/// The interpreter takes the decimal value of Vx, and places the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.
/// - Parameter operation: Fx33 - LD B, Vx
func BCD(opcode: Opcode, chip: inout Chip8) {
    
}

/// Store registers V0 through Vx in memory starting at location I.
/// The interpreter copies the values of registers V0 through Vx into memory, starting at the address in I.
/// - Parameter operation: Fx55 - LD [I], Vx
func STOR(opcode: Opcode, chip: inout Chip8) {
    
}

/// Read registers V0 through Vx from memory starting at location I.
/// The interpreter reads values from memory starting at location I into registers V0 through Vx.
/// - Parameter operation: Fx65 - LD Vx, [I]
func READ(opcode: Opcode, chip: inout Chip8) {
    
}
