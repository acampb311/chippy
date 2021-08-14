//
//  chippyTests.swift
//  chippyTests
//
//  Created by Adam Campbell on 7/25/21.
//

import XCTest

@testable import chippy

class chippyTests: XCTestCase {
    
    func testReturnFromSubroutine() throws {
        // Given
        var chip8 = Chip8()
        chip8.stack = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,0x0B, 0x0C, 0x0D, 0x0E, 0x0F]
        chip8.SP = 0x5
        
        // When
        RTS(opcode: Opcode(instruction: 0x00EE), chip: &chip8)
       
        // Then
        XCTAssertEqual(chip8.PC, 0x05)
        XCTAssertEqual(chip8.SP, 0x04)
    }
    
    func testJumpToLocation() throws {
        // Given
        var chip8 = Chip8()
        
        // When
        JUMP(opcode: Opcode(instruction: 0x1432), chip: &chip8)
        
        // Then
        XCTAssertEqual(chip8.PC, 0x432)
    }
    
    func testLoadIntoRegister() throws {
        // Given
        var chip8 = Chip8()
        
        // When
        LOAD(opcode: Opcode(instruction: 0x6EFF), chip: &chip8)
        
        // Then
        XCTAssertEqual(chip8.registers[14], 0xFF)
    }
    
    func testAddToRegister() throws {
        // Given
        var chip8 = Chip8()
        
        // When
        LOAD(opcode: Opcode(instruction: 0x6EEE), chip: &chip8)
        ADD(opcode: Opcode(instruction: 0x7E11), chip: &chip8)

        // Then
        XCTAssertEqual(chip8.registers[14], 0xFF)
    }
    
    func testSetIndexRegister() throws {
        // Given
        var chip8 = Chip8()
        
        // When
        LOADI(opcode: Opcode(instruction: 0xAABC), chip: &chip8)
        
        // Then
        XCTAssertEqual(chip8.I, 0xABC)
        
        
        // When
        LOADI(opcode: Opcode(instruction: 0xA100), chip: &chip8)
        
        // Then
        XCTAssertEqual(chip8.I, 0x100)
    }
}
