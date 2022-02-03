//
//  Chip8.swift
//  chippy
//
//  Created by Adam Campbell on 7/18/21.
//

import Foundation
import SpriteKit
import SwiftUI
import Collections

let STACK_SIZE = 16
let RAM_SIZE = 4096
let REGISTER_SIZE = 16

extension String: LocalizedError {
   public var errorDescription: String? { return self }
}

enum Chip8Error: Error {
   case invalidParameterForOpcode
   case invalidOpcodeContents
   case opcodeNotImplemented
}

public struct InstructionInfo : Identifiable {
   public let id = UUID()
   public var description: String = ""
   public var address: UInt32
   public var breakHere: Bool = false
   public var instruction: UInt32
}

public class Chip8 : ObservableObject {
   @Published public var visibileData: OrderedDictionary<String,String>
   @Published public var allInstructions: [InstructionInfo]
   public var display: Display
   public var gameTimer: Timer?
   public var delayTimer: Timer?
   public var currentChip: Chip8?
   
   var registers = [UInt8](repeatElement(0x0, count: REGISTER_SIZE))
   var I: UInt16 = 0x00
   var PC: UInt16 = 0x00
   var SP: UInt8 = 0x00
   var DT: UInt8 = 0x00
   var ST: UInt8 = 0x00
   var ram: [UInt8] = [UInt8](repeatElement(0x00, count: RAM_SIZE))
   var stack: [UInt16] = [UInt16](repeatElement(0x0000, count: STACK_SIZE))
   var keyboard = [UInt8](repeatElement(0x0, count: REGISTER_SIZE))
   var romSize: Int
   var lastInstrBreak: UInt32 = 0x0000
   
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
   
   public init() {
      ram.replaceSubrange(0x0..<font.count, with: font)
      display = Display()
      display.size = CGSize(width: 64, height: 32)
      display.scaleMode = .aspectFill
      display.createDisplay(pixelsWide: 64, pixelsHigh: 32)
      allInstructions = []
      visibileData = [:]
      romSize = 0

      PopulateVisibleData()
   }
   
   func PopulateVisibleData() {
      DispatchQueue.main.async {
         self.visibileData["PC"] = String(format: "0x%04X", self.PC)
         self.visibileData["I"] = String(format: "0x%04X", self.I)
         self.visibileData["SP"] = String(format: "0x%04X", self.SP)
         
         for i in self.stack.indices {
            self.visibileData[String(format: "SP%01X", i)] = String(format: "0x%04X", self.stack[i])
         }
         
         for i in self.registers.indices {
            self.visibileData[String(format: "V%01X", i)] = String(format: "0x%02X", self.registers[i])
         }
      }
   }
   
   @objc
   public func delayStep() {
      
      if (DT > 0)
      {
         DT -= 1
      }
   }
   
   @objc
   public func Step() {
      
      let instruction = UInt32((UInt32(ram[Int(PC)+0]) << 8) |
                               (UInt32(ram[Int(PC)+1]) << 0) )
      PC += 2
      if let operation = opcodeMap[Opcode(instruction: instruction)] {
         do {
            if let instr = allInstructions.first(where: {$0.instruction == instruction}) {
               if instr.breakHere && lastInstrBreak != instruction {
                  gameTimer?.invalidate()
                  delayTimer?.invalidate()
                  lastInstrBreak = instruction
                  PC -= 2
               }
               else
               {
                  try operation(Opcode(instruction: instruction), &currentChip!, false)
                  lastInstrBreak = 0x0000
               }
            }
            
            PopulateVisibleData()
         }
         catch {
            print("error calling operation. \(error)")
         }
      }
   }
   
   public func LoadRom(rom: [UInt8]) {
      registers = [UInt8](repeatElement(0x0, count: REGISTER_SIZE))
      I = 0
      SP = 0
      DT = 0
      ST = 0
      
      allInstructions = []
      ram.replaceSubrange(0x200..<rom.count+0x200, with: rom)
      PC = 0x200 //Chip8 roms are traditionally loaded starting at byte 512, 0x200
      romSize = rom.count + 0x200
      

      display.clear()
      ProcessAllInstructions()
   }
   
   public func ProcessAllInstructions() {
      var chippy: Chip8 = Chip8()
      for addr in stride(from: 0x200, to: romSize, by: 1) {
         let instruction = UInt32((UInt32(ram[addr+0]) << 8) |
                                  (UInt32(ram[addr+1]) << 0) )
         
         if let operation = opcodeMap[Opcode(instruction: instruction)] {
            do {
               try operation(Opcode(instruction: instruction), &chippy, true)
            }
            catch {
               self.allInstructions.append(InstructionInfo(description: String("\(error)"),
                                                           address: UInt32(addr),
                                                           breakHere: false,
                                                           instruction: instruction))
            }
         }
      }
   }
   
   public func SetKey(key: Int) {
      keyboard[key] = 0x01
   }
   
   public func ClearKey(key: Int) {
      keyboard[key] = 0x00
   }
   
   let opcodeMap =
   [
       Opcode(0x0, 0x0, 0xE, 0x0): CLS,
       Opcode(0x0, 0x0, 0xE, 0xE): RTS,
       Opcode(0x1, nil, nil, nil): JUMP,
       Opcode(0x2, nil, nil, nil): CALL,
       Opcode(0x3, nil, nil, nil): SKE,
       Opcode(0x4, nil, nil, nil): SKNE,
       Opcode(0x5, nil, nil, 0x0): SKRE,
       Opcode(0x6, nil, nil, nil): LOAD,
       Opcode(0x7, nil, nil, nil): ADD,
       Opcode(0x8, nil, nil, 0x0): MOVE,
       Opcode(0x8, nil, nil, 0x1): OR,
       Opcode(0x8, nil, nil, 0x2): AND,
       Opcode(0x8, nil, nil, 0x3): XOR,
       Opcode(0x8, nil, nil, 0x4): ADDR,
       Opcode(0x8, nil, nil, 0x5): SUB,
       Opcode(0x8, nil, nil, 0x6): SHR,
       Opcode(0x8, nil, nil, 0x7): SUBN,
       Opcode(0x8, nil, nil, 0xE): SHL,
       Opcode(0x9, nil, nil, 0x0): SKRNE,
       Opcode(0xA, nil, nil, nil): LOADI,
       Opcode(0xB, nil, nil, nil): JUMPI,
       Opcode(0xC, nil, nil, nil): RAND,
       Opcode(0xD, nil, nil, nil): DRAW,
       Opcode(0xE, nil, 0x9, 0xE): SKPR,
       Opcode(0xE, nil, 0xA, 0x1): SKUP,
       Opcode(0xF, nil, 0x0, 0x7): MOVED,
       Opcode(0xF, nil, 0x0, 0xA): KEYD,
       Opcode(0xF, nil, 0x1, 0x5): LOADD,
       Opcode(0xF, nil, 0x1, 0x8): LOADS,
       Opcode(0xF, nil, 0x1, 0xE): ADDI,
       Opcode(0xF, nil, 0x2, 0x9): LDSPR,
       Opcode(0xF, nil, 0x3, 0x3): BCD,
       Opcode(0xF, nil, 0x5, 0x5): STOR,
       Opcode(0xF, nil, 0x6, 0x5): READ
   ]
}


/// Clears the screen
/// - Parameters:
///   - opcode: 0x00E0
///   - chip: chip8 instance to operate on
func CLS(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0x0, 0x0, 0xE, 0x0) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   if throwDescription {
      throw "Clear Screen"
   }
   
   chip.display.clear()
}

/// Returns from a subroutine.
/// - Parameters:
///   - opcode: 0x00EE
///   - chip: chip8 instance to operate on
func RTS(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0x0, 0x0, 0xE, 0xE) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   if throwDescription {
      throw "Return to SP"
   }
   
   chip.PC = chip.stack[Int(chip.SP)]
   chip.SP = chip.SP - 1
}

/// Jump to location nnn.
/// The interpreter sets the program counter to nnn.
/// - Parameter operation: 1nnn - JP addr
func JUMP(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(1, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let address = opcode.GetNNN() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Jump \(String(format: "0x%04X", address))"
   }
   
   chip.PC = address
}

/// Call subroutine at nnn.
/// The interpreter increments the stack pointer, then puts the current PC on the top of the stack. The PC is then set to nnn.
/// - Parameter operation: 2nnn - CALL addr
func CALL(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(2, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let address = opcode.GetNNN() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Call \(String(format: "0x%04X", address))"
   }
   
   chip.SP += 1
   chip.stack[Int(chip.SP)] = chip.PC
   chip.PC = address
}

/// Skip next instruction if Vx = kk.
/// The interpreter compares register Vx to kk, and if they are equal, increments the program counter by 2.
/// - Parameter operation: 3xkk - SE Vx, byte
func SKE(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(3, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let value = opcode.GetNN(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if \(value) == \(String(format: "V%01X", xIndex))"
   }
   
   if chip.registers[Int(xIndex)] == value {
      chip.PC += 2
   }
}

/// Skip next instruction if Vx != kk.
/// The interpreter compares register Vx to kk, and if they are not equal, increments the program counter by 2.
/// - Parameter operation: 4xkk - SNE Vx, byte
func SKNE(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(4, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let value = opcode.GetNN(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if \(String(format: "0x%02X", value)) != \(String(format: "V%01X", xIndex))"
   }
   
   if chip.registers[Int(xIndex)] != value {
      chip.PC += 2
   }
}

/// Skip next instruction if Vx = Vy.
/// The interpreter compares register Vx to register Vy, and if they are equal, increments the program counter by 2.
/// - Parameter operation: 5xy0 - SE Vx, Vy
func SKRE(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(5, nil, nil, 0x0) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if \(String(format: "V%01X", xIndex)) == \(String(format: "V%01X", yIndex))"
   }
   
   if chip.registers[Int(xIndex)] == chip.registers[Int(yIndex)]  {
      chip.PC += 2
   }
}

/// Set Vx = kk.
/// The interpreter puts the value kk into register Vx.
/// - Parameter operation: 6xkk - LD Vx, byte
func LOAD(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(6, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let value = opcode.GetNN(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) = \(String(format: "0x%02X", value))"
   }
   
   chip.registers[xIndex] = value
}

/// Set Vx = Vx + kk.
/// Adds the value kk to the value of register Vx, then stores the result in Vx.
/// - Parameter operation: 7xkk - ADD Vx, byte
func ADD(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(7, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let value = opcode.GetNN(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) += \(String(format: "0x%02X", value))"
   }
   
   let total: Int = Int(chip.registers[xIndex]) + Int(value)
   chip.registers[xIndex] = UInt8(total & 0xFF)
}

/// Set Vx = Vy.
/// Stores the value of register Vy in register Vx.
/// - Parameter operation: 8xy0 - LD Vx, Vy
func MOVE(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 0) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) = \(String(format: "V%01X", yIndex))"
   }
      
   chip.registers[xIndex] = chip.registers[yIndex]
}

/// Set Vx = Vx OR Vy.
/// Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx. A bitwise OR compares the corrseponding bits from two values, and if either bit is 1, then the same bit in the result is also 1. Otherwise, it is 0.
/// - Parameter operation: 8xy1 - OR Vx, Vy
func OR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 1) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) |= \(String(format: "V%01X", yIndex))"
   }
   
   chip.registers[xIndex] |= chip.registers[yIndex]
}


/// Set Vx = Vx AND Vy.
/// Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx. A bitwise AND compares the corrseponding bits from two values, and if both bits are 1, then the same bit in the result is also 1. Otherwise, it is 0.
/// - Parameter operation: 8xy2 - AND Vx, Vy
func AND(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 2) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) &= \(String(format: "V%01X", yIndex))"
   }
   
   chip.registers[xIndex] &= chip.registers[yIndex]
}

/// Set Vx = Vx XOR Vy.
/// Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx. An exclusive OR compares the corrseponding bits from two values, and if the bits are not both the same, then the corresponding bit in the result is set to 1. Otherwise, it is 0.
/// - Parameter operation: 8xy3 - XOR Vx, Vy
func XOR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 3) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) ^= \(String(format: "V%01X", yIndex))"
   }
   
   chip.registers[xIndex] ^= chip.registers[yIndex]
}

/// Set Vx = Vx + Vy, set VF = carry.
/// The values of Vx and Vy are added together. If the result is greater than 8 bits (i.e., > 255,) VF is set to 1, otherwise 0. Only the lowest 8 bits of the result are kept, and stored in Vx.
/// - Parameter operation: 8xy4 - ADD Vx, Vy
func ADDR (opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 4) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) += \(String(format: "V%01X", yIndex))"
   }
   
   let total: Int = Int(chip.registers[xIndex]) + Int((chip.registers[yIndex]))
   if total > 255 {
      chip.registers[0xF] = 1
   }
   
   chip.registers[xIndex] = UInt8(total & 0xFF)
}

/// Set Vx = Vx - Vy, set VF = NOT borrow.
/// If Vx > Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results stored in Vx.
/// - Parameter operation: 8xy5 - SUB Vx, Vy
func SUB(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 5) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if chip.registers[xIndex] > chip.registers[yIndex] {
      chip.registers[0xF] = 1
   } else {
      chip.registers[0xF] = 0
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) -= \(String(format: "V%01X", yIndex))"
   }
   
   let total: Int = Int(chip.registers[xIndex]) - Int((chip.registers[yIndex]))
   
   chip.registers[xIndex] = UInt8(total & 0xFF)
}


/// Set Vx = Vx SHR 1.
/// If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
/// - Parameter operation: 8xy6 - SHR Vx {, Vy}
func SHR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 6) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) = \(String(format: "V%01X", xIndex)) SHR 1"
   }
   
   chip.registers[0xF] = chip.registers[xIndex] & 0b00000001
   chip.registers[xIndex] >>= 1
}

/// Set Vx = Vy - Vx, set VF = NOT borrow.
/// If Vy > Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy, and the results stored in Vx.
/// - Parameter operation: 8xy7 - SUBN Vx, Vy
func SUBN(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 7) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) = \(String(format: "V%01X", yIndex)) - \(String(format: "V%01X", xIndex))"
   }
   
   if chip.registers[yIndex] > chip.registers[xIndex] {
      chip.registers[0xF] = 1
   } else {
      chip.registers[0xF] = 0
   }
   
   let total: Int = Int(chip.registers[yIndex]) - Int((chip.registers[xIndex]))
   
   chip.registers[xIndex] = UInt8(total & 0xFF)
}

/// Set Vx = Vx SHL 1.
/// If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
/// - Parameter operation: 8xyE - SHL Vx {, Vy}
func SHL(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(8, nil, nil, 0xE) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%01X", xIndex)) = \(String(format: "V%01X", xIndex)) SHL 1"
   }
   
   chip.registers[0xF] = (chip.registers[xIndex] & 0b10000000) >> 7
   chip.registers[xIndex] <<= 1
}

/// Skip next instruction if Vx != Vy.
/// The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
/// - Parameter operation: 9xy0 - SNE Vx, Vy
func SKRNE(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(9, nil, nil, 0x0) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let yIndex = opcode.GetY(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if \(String(format: "V%01X", xIndex)) != \(String(format: "V%01X", yIndex))"
   }
   
   if chip.registers[Int(xIndex)] != chip.registers[Int(yIndex)]  {
      chip.PC += 2
   }
}

/// Set I = nnn.
/// The value of register I is set to nnn.
/// - Parameter operation: Annn - LD I, addr
func LOADI(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xA, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let address = opcode.GetNNN() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "I = \(String(format: "V%04X", address))"
   }
   
   chip.I = (address & 0xFFF)
}

/// Jump to location nnn + V0.
/// The program counter is set to nnn plus the value of V0.
/// - Parameter operation: Bnnn - JP V0, addr
func JUMPI(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xB, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let address = opcode.GetNNN() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Jump \(String(format: "V%04X", address)) + V0"
   }
   
   chip.PC = (UInt16(chip.registers[0]) & 0xFFF) + address
}

/// Set Vx = random byte AND kk.
/// The interpreter generates a random number from 0 to 255, which is then ANDed with the value kk. The results are stored in Vx. See instruction 8xy2 for more information on AND.
/// - Parameter operation: Cxkk - RND Vx, byte
func RAND(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   
   if opcode != Opcode(0xC, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let value = opcode.GetNN(),
         let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%02X", xIndex)) = RAND & \(String(format: "V%02X", value))"
   }
   
   chip.registers[xIndex] = UInt8(Int.random(in: 0..<256)) & value
}

/// Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
/// The interpreter reads n bytes from memory, starting at the address stored in I. These bytes are then displayed as sprites on screen at coordinates (Vx, Vy). Sprites are XORed onto the existing screen. If this causes any pixels to be erased, VF is set to 1, otherwise it is set to 0. If the sprite is positioned so part of it is outside the coordinates of the display, it wraps around to the opposite side of the screen.
/// - Parameter operation: Dxyn - DRW Vx, Vy, nibble
func DRAW(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   
   if opcode != Opcode(0xD, nil, nil, nil) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX(),
         let yIndex = opcode.GetY(),
         let mheight = opcode.GetN()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Draw x:\(String(format: "V[%01X]", xIndex)) y:\(String(format: "V[%01X]", yIndex)) h: \(mheight)"
   }
   
   let opx = chip.registers[xIndex]
   let opy = chip.registers[yIndex]
   
   // Clear the collision register
   chip.registers[0xF] = 0
   
   for yline in 0..<mheight {
      let line = chip.ram[Int(chip.I)+Int(yline)]
      
      for xline in 0...7 {
         let pixel = line & (0x80 >> xline)
         if (pixel != 0)
         {
            if (chip.display.setPixel(x: Int(opx)+Int(xline), y: (Int(opy)+Int(yline))))
            {
               // if there was a collision in any of the pixels, the function will return true.
               // we need to flip the VF register accordingly
               chip.registers[0xF] = 1
            }
         }
      }
   }
}

/// Skip next instruction if key with the value of Vx is pressed.
/// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the down position, PC is increased by 2.
/// - Parameter operation: Ex9E - SKP Vx
func SKPR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xE, nil, 0x9, 0xE) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if key \(String(format: "V%02X", xIndex))"
   }
   
   if chip.keyboard[xIndex] == 0x01 {
      chip.PC += 2
   }
}

/// Skip next instruction if key with the value of Vx is not pressed.
/// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the up position, PC is increased by 2.
/// - Parameter operation: ExA1 - SKNP Vx
func SKUP(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xE, nil, 0xA, 0x1) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Skip if key up \(String(format: "V%02X", xIndex))"
   }
   
   if chip.keyboard[xIndex] == 0x00 {
      chip.PC += 2
   }
}

/// Set Vx = delay timer value.
/// The value of DT is placed into Vx.
/// - Parameter operation: Fx07 - LD Vx, DT
func MOVED(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x0, 0x7) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "\(String(format: "V%02X", xIndex)) = DT"
   }
   
   chip.registers[xIndex] = chip.DT
}

/// Wait for a key press, store the value of the key in Vx.
/// All execution stops until a key is pressed, then the value of that key is stored in Vx.
/// - Parameter operation: Fx0A - LD Vx, K
func KEYD(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x0, 0xA) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX()
   else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "Wait for key \(String(format: "V%02X", xIndex))"
   }
   
   for i in 0..<16 {
      if chip.keyboard[i] == 0x01 {
         chip.registers[xIndex] = UInt8(i)
         break
      }
   }
}

/// Set delay timer = Vx.
/// DT is set equal to the value of Vx.
/// - Parameter operation: Fx15 - LD DT, Vx
func LOADD(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x1, 0x5) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "DT = \(String(format: "V%02X", xIndex))"
   }
   
   chip.DT = chip.registers[xIndex]
}

/// Set sound timer = Vx.
/// ST is set equal to the value of Vx.
/// - Parameter operation: Fx18 - LD ST, Vx
func LOADS(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x1, 0x8) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "ST = \(String(format: "V%02X", xIndex))"
   }
   
   chip.ST = chip.registers[xIndex]
}

/// Set I = I + Vx.
/// The values of I and Vx are added, and the results are stored in I.
/// - Parameter operation: Fx1E - ADD I, Vx
func ADDI(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x1, 0xE) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "I += \(String(format: "V%02X", xIndex))"
   }
   
   chip.I += UInt16(chip.registers[xIndex])
}

/// Set I = location of sprite for digit Vx.
/// The value of I is set to the location for the hexadecimal sprite corresponding to the value of Vx.
/// - Parameter operation: Fx29 - LD F, Vx
func LDSPR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x2, 0x9) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "I = \(String(format: "V%02X", xIndex)) * 5"
   }
   
   chip.I = UInt16(xIndex * 5)
}

/// Store BCD representation of Vx in memory locations I, I+1, and I+2.
/// The interpreter takes the decimal value of Vx, and places the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.
/// - Parameter operation: Fx33 - LD B, Vx
func BCD(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x3, 0x3) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "BCD"
   }
   
   chip.ram[Int(chip.I + 0)] = UInt8((Int(chip.registers[xIndex]) / 100) % 10)
   chip.ram[Int(chip.I + 1)] = UInt8((Int(chip.registers[xIndex]) / 10 ) % 10)
   chip.ram[Int(chip.I + 2)] = UInt8((Int(chip.registers[xIndex]) / 1  ) % 10)
}

/// Store registers V0 through Vx in memory starting at location I.
/// The interpreter copies the values of registers V0 through Vx into memory, starting at the address in I.
/// - Parameter operation: Fx55 - LD [I], Vx
func STOR(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x5, 0x5) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "STOR"
   }
   
   for n in 0...xIndex {
      chip.ram[Int(chip.I) + n] = chip.registers[n]
   }
   
//   chip.I += UInt16(xIndex + 1)
}

/// Read registers V0 through Vx from memory starting at location I.
/// The interpreter reads values from memory starting at location I into registers V0 through Vx.
/// - Parameter operation: Fx65 - LD Vx, [I]
func READ(opcode: Opcode, chip: inout Chip8, throwDescription: Bool) throws {
   if opcode != Opcode(0xF, nil, 0x6, 0x5) {
      throw Chip8Error.invalidParameterForOpcode
   }
   
   guard let xIndex = opcode.GetX() else {
      throw Chip8Error.invalidOpcodeContents
   }
   
   if throwDescription {
      throw "READ"
   }
   
   for n in 0...xIndex {
      chip.registers[n] = chip.ram[Int(chip.I) + n]
   }
   
//   chip.I += UInt16(xIndex + 1)
}

