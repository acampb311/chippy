//
//  Opcode.swift
//  chippy
//
//  Created by Adam Campbell on 8/7/21.
//

import Foundation

struct Opcode: Hashable {
    
    let first: UInt8?
    let second: UInt8?
    let third: UInt8?
    let fourth: UInt8?
    
    init(first: UInt8?, second: UInt8?, third: UInt8?, fourth: UInt8?) {
        self.first = first
        self.second = second
        self.third = third
        self.fourth = fourth
    }
    
    init(instruction: UInt32) {
        self.first  = UInt8((instruction & 0xF000) >> 12)
        self.second = UInt8((instruction & 0x0F00) >> 8)
        self.third  = UInt8((instruction & 0x00F0) >> 4)
        self.fourth = UInt8((instruction & 0x000F) >> 0)
    }
    
    /// Opcodes in the Chip8 spec utilize the lower three bytes to specify an address.
    /// This address can only ever be 12 bits, but we use UInt16 as a convenient container
    /// - Returns: The combined lower three bytes of the opcode
    func GetNNN() -> UInt16? {
        guard let tempSecond = self.second,
              let tempThird  = self.third,
              let tempFourth = self.fourth else {
            print("second, third, or fourth byte in opcode was nil")
            return nil
        }
        
        return  UInt16(tempSecond) << 8 |
            UInt16(tempThird)  << 4 |
            UInt16(tempFourth) << 0
    }
    
    /// Opcodes in the Chip8 spec utilize the lower two bytes specify an 8 bit constant value
    /// - Returns: The combined lower two bytes of the opcode
    func GetNN() -> UInt8? {
        guard let tempThird = self.third,
              let tempFourth = self.fourth
        else {
            print("third or fourth byte in opcode was nil")
            return nil
        }
        
        return UInt8(tempThird)  << 4 |
            UInt8(tempFourth) << 0
    }
    
    /// Opcodes in the Chip8 spec utilize the lowest byte specify a 4 bit constant value
    /// - Returns: The lowest byte of the opcode
    func GetN() -> UInt8? {
        guard let tempFourth = self.fourth else {
            print("fourth byte in opcode was nil")
            return nil
        }
        
        return UInt8(tempFourth)
    }
    
    /// Opcodes in the Chip8 spec can utilize the second byte to specify a 4 bit offset into the chip's register array of 16 registers
    /// - Returns: The second byte of the opcode
    func GetX() -> Int? {
        guard let tempX = self.second else {
            print("second byte in opcode was nil")
            return nil
        }
        
        return Int(tempX)
    }
    
    /// Opcodes in the Chip8 spec can utilize the third byte to specify a 4 bit offset into the chip's register array of 16 registers
    /// - Returns: The third byte of the opcode
    func GetY() -> Int? {
        guard let tempY = self.third else {
            print("third byte in opcode was nil")
            return nil
        }
        
        return Int(tempY)
    }
    
    func hash(into hasher: inout Hasher) {
        // I am content to sacrifice performance for capability. Force comparison using equality override.
        hasher.combine(0)
    }
    
    static func ==(lhs: Opcode, rhs: Opcode) -> Bool {
        
        var first = false
        var second = false
        var third = false
        var fourth = false
        //if an entry on one side is null, don't include it in the comparison
        //this is to allow a map of instructions to contain nil values.
        if let lFirst = lhs.first,
           let rFirst = rhs.first {
            first = lFirst == rFirst
        }
        else {
            first = true
        }
        
        if let lSecond = lhs.second,
           let rSecond = rhs.second {
            second = lSecond == rSecond
        } else {
            second = true
        }
        
        if let lThird = lhs.third,
           let rThird = rhs.third {
            third = lThird == rThird
        } else {
            third = true
        }
        
        if let lFourth = lhs.fourth,
           let rFourth = rhs.fourth {
            fourth = lFourth == rFourth
        } else {
            fourth = true
        }
        
        return first && second && third && fourth
    }
}
