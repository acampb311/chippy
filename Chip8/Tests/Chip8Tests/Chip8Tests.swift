import XCTest
@testable import Chip8

final class Chip8Tests: XCTestCase {
    func testReturnFromSubroutine() throws {
       // Given
       var chip8 = Chip8()
       chip8.stack = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F]
       chip8.SP = 0x5
       
       // When
       try RTS(opcode: Opcode(instruction: 0x00EE), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x05)
       XCTAssertEqual(chip8.SP, 0x04)
    }
    
    func testJumpToLocation() throws {
       // Given
       var chip8 = Chip8()
       
       // When
       try JUMP(opcode: Opcode(instruction: 0x1432), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x432)
    }
    
    func testLoadIntoRegister() throws {
       // Given
       var chip8 = Chip8()
       
       // When
       try LOAD(opcode: Opcode(instruction: 0x6EFF), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers[14], 0xFF)
    }
    
    func testAddToRegister() throws {
       // Given
       var chip8 = Chip8()
       
       // When
       try LOAD(opcode: Opcode(instruction: 0x6EEE), chip: &chip8, throwDescription: false)
       try ADD(opcode: Opcode(instruction: 0x7E11), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers[14], 0xFF)
    }
    
    func testSetIndexRegister() throws {
       // Given
       var chip8 = Chip8()
       
       // When
       try LOADI(opcode: Opcode(instruction: 0xAABC), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.I, 0xABC)
       
       
       // When
       try LOADI(opcode: Opcode(instruction: 0xA100), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.I, 0x100)
    }
    
    func testCall() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.stack = [0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF, 0x00CA, 0x0000, 0x0000, 0x0000]
       chip8.SP = 0x0C
       chip8.PC = 0x0ABC
       
       // When
       try CALL(opcode: Opcode(instruction: 0x2DEF), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.SP, 0x0D)
       XCTAssertEqual(chip8.PC, 0x0DEF)
       XCTAssertEqual(chip8.stack, [0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF, 0x00CA, 0x0ABC, 0x0000, 0x0000])

    }
    
    func testSkipNextInstrEqual() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.PC = 0x02

       // When
       try SKE(opcode: Opcode(instruction: 0x3FAB), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x02)
       
       // When
       try SKE(opcode: Opcode(instruction: 0x3FAA), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x04)
    }
    
    func testSkipNextInstrNotEqual() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.PC = 0x02

       // When
       try SKNE(opcode: Opcode(instruction: 0x4FAB), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x04)
       
       // When
       try SKNE(opcode: Opcode(instruction: 0x4FAA), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x04)
    }
    
    func testSkipNextInstrRegistersEqual() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.PC = 0x02

       // When
       try SKRE(opcode: Opcode(instruction: 0x5F00), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x02)
       
       // When
       try SKRE(opcode: Opcode(instruction: 0x5F10), chip: &chip8, throwDescription: false)

       // Then
       XCTAssertEqual(chip8.PC, 0x04)
    }
    
    func testStoreXinY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]

       // When
       try MOVE(opcode: Opcode(instruction: 0x80F0), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0xAA, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA])
    }
    
    func testXOrY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0b11110000, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]

       // When
       try OR(opcode: Opcode(instruction: 0x8011), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b11110011, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA])
    }
    
    func testXAndY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0b11110000, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]

       // When
       try AND(opcode: Opcode(instruction: 0x8012), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b00110000, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA])
    }
    
    func testXXorY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0b11110000, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]

       // When
       try XOR(opcode: Opcode(instruction: 0x8013), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b11000011, 0b00110011, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA])
    }
    
    func testXAddRY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try ADDR(opcode: Opcode(instruction: 0x8014), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0xAA, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
       
       // Given
       chip8.registers = [0xAA, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try ADDR(opcode: Opcode(instruction: 0x8014), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0x54, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
    }
    
    func testXSubRY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SUB(opcode: Opcode(instruction: 0x8015), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0x56, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
       
       // Given
       chip8.registers = [0xFF, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SUB(opcode: Opcode(instruction: 0x8015), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0x55, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
    }
    
    func testXSHRY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0b00000111, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SHR(opcode: Opcode(instruction: 0x8016), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b00000011, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
       
       // Given
       chip8.registers = [0b00000110, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SHR(opcode: Opcode(instruction: 0x8016), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b00000011, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
    
    func testXSubNY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SUBN(opcode: Opcode(instruction: 0x8017), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0xAA, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
       
       // Given
       chip8.registers = [0xFF, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SUBN(opcode: Opcode(instruction: 0x8017), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0xAB, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
    
    func testXSHLY() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0b10000111, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SHL(opcode: Opcode(instruction: 0x801E), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b00001110, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
       
       // Given
       chip8.registers = [0b00000110, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

       // When
       try SHL(opcode: Opcode(instruction: 0x801E), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0b00001100, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
    
    func testSkipNextInstrRegNotEqual() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.PC = 0x02

       // When
       try SKRNE(opcode: Opcode(instruction: 0x9010), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0x04)
       
       // Given
       chip8.registers = [0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.PC = 0x02
       
       // When
       try SKRNE(opcode: Opcode(instruction: 0x9010), chip: &chip8, throwDescription: false)

       // Then
       XCTAssertEqual(chip8.PC, 0x02)
    }
    
    func testJumpToLocationWithReg() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       // When
       try JUMPI(opcode: Opcode(instruction: 0xBABC), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.PC, 0xABD)
    }
    
    func testSetVxToDelayTimer() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.DT = 0x45
       
       // When
       try MOVED(opcode: Opcode(instruction: 0xF007), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA])
    }
    
    func testSetDelayTimerToVx() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.DT = 0x45
       
       // When
       try LOADD(opcode: Opcode(instruction: 0xF015), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.DT, 0x01)
    }
    
    func testSetSoundTimerToVx() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.ST = 0x45
       
       // When
       try LOADS(opcode: Opcode(instruction: 0xF018), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.ST, 0x01)
    }
    
    func testAddIandReg() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.registers = [0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       chip8.I = 0x45
       
       // When
       try ADDI(opcode: Opcode(instruction: 0xF01E), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.I, 0x56)
    }
    
    func testBinaryCodedDecimal() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.I = 0x100
             
       chip8.registers = [245, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA]
       
       // When
       try BCD(opcode: Opcode(instruction: 0xF033), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.ram[Int(chip8.I + 0)], 2)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 1)], 4)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 2)], 5)
    }
    
    func testStoreRegistersInMemory() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.I = 0x100
             
       chip8.registers = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F]
       
       // When
       try STOR(opcode: Opcode(instruction: 0xFF55), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.ram[Int(chip8.I + 0)], 0)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 1)], 1)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 2)], 2)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 3)], 3)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 4)], 4)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 5)], 5)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 6)], 6)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 7)], 7)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 8)], 8)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 9)], 9)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 10)], 10)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 11)], 11)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 12)], 12)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 13)], 13)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 14)], 14)
       XCTAssertEqual(chip8.ram[Int(chip8.I + 15)], 15)

    }
    
    func testLoadMemoryIntoRegisters() throws {
       // Given
       var chip8 = Chip8()
       
       chip8.I = 0x100
       
       chip8.ram[Int(chip8.I) + 0] = 0x00
       chip8.ram[Int(chip8.I) + 1] = 0x01
       chip8.ram[Int(chip8.I) + 2] = 0x02
       chip8.ram[Int(chip8.I) + 3] = 0x03
       chip8.ram[Int(chip8.I) + 4] = 0x04
       chip8.ram[Int(chip8.I) + 5] = 0x05
       chip8.ram[Int(chip8.I) + 6] = 0x06
       chip8.ram[Int(chip8.I) + 7] = 0x07
       chip8.ram[Int(chip8.I) + 8] = 0x08
       chip8.ram[Int(chip8.I) + 9] = 0x09
       chip8.ram[Int(chip8.I) + 10] = 0x0A
       chip8.ram[Int(chip8.I) + 11] = 0x0B
       chip8.ram[Int(chip8.I) + 12] = 0x0C
       chip8.ram[Int(chip8.I) + 13] = 0x0D
       chip8.ram[Int(chip8.I) + 14] = 0x0E
       chip8.ram[Int(chip8.I) + 15] = 0x0F
       
       // When
       try READ(opcode: Opcode(instruction: 0xFF65), chip: &chip8, throwDescription: false)
       
       // Then
       XCTAssertEqual(chip8.registers, [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F])
    }
}
