//
//  ContentView.swift
//  chippy
//
//  Created by Adam Campbell on 7/15/21.
//

import SwiftUI
import SpriteKit
import Combine
import Chip8

struct ContentView: View {
   @ObservedObject private var chip8 = Chip8()
   
   var body: some View {
      NavigationView {
         ScrollView {
            RomView(currentChip: chip8)
            RegisterView(currentChip: chip8)
            InstrView(currentChip: chip8)
         }
         .toolbar {
            Button(action: { StopChipTimers(chip8: chip8) }) {
               Label("Stop", systemImage: "stop.fill")
            }
            Button(action: { StartChipTimers(chip8: chip8) }) {
               Label("Play", systemImage: "play.fill")
            }
            Button(action: { chip8.Step() }) {
               Label("Record Progress", systemImage: "forward.fill")
            }
         }
         // Aspect ratio of 2 comes from 640 width / 320 height
         SpriteView(scene: chip8.display).aspectRatio(2, contentMode: .fit)
      }
      .onAppear(perform: { chip8.currentChip = chip8 })
   }
}

func StopChipTimers(chip8: Chip8) {
   chip8.gameTimer?.invalidate();
   chip8.delayTimer?.invalidate()
}

func StartChipTimers(chip8: Chip8) {
   //               DispatchQueue.global(qos: .userInteractive).async {
   chip8.gameTimer = Timer(timeInterval: 1/300, target: chip8, selector: #selector(chip8.Step), userInfo: nil, repeats: true)
   RunLoop.current.add(chip8.gameTimer!, forMode: .common)
   //                  let runLoop = RunLoop.current
   //                  runLoop.add(chip8.gameTimer!, forMode: .default)
   //                  runLoop.run()
   //               }
   
   //               DispatchQueue.global(qos: .userInteractive).async {
   chip8.delayTimer = Timer(timeInterval: 1/60, target: chip8, selector: #selector(chip8.delayStep), userInfo: nil, repeats: true)
   RunLoop.current.add(chip8.delayTimer!, forMode: .common)
   //                  let runLoop = RunLoop.current
   //                  runLoop.add(chip8.delayTimer!, forMode: .default)
   //                  runLoop.run()
   //               }
}

struct RomView: View {
   @ObservedObject var currentChip: Chip8
   
   @State var filename = "ROM"
   @State var showFileChooser = false
   
   var body: some View {
      HStack {
         Text(filename)
         Button("Select ROM")
         {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
               self.filename = panel.url?.lastPathComponent ?? "<none>"
               if let content = NSData(contentsOf: panel.url!) {
                  currentChip.loadRom(rom: [UInt8](content))
               }
            }
         }
      }.padding(5)
   }
}

struct InstrView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   @ObservedObject var currentChip: Chip8
   @State private var sortOrder = [KeyPathComparator(\InstructionInfo.operation)]
   @State private var vibrateOnRing = false
   @State private var idealWidth: CGFloat = 20
   
   var body: some View {
      GroupBox() {
         Table(currentChip.allInstructions, selection: $currentChip.currentInstruction, sortOrder: $sortOrder) {
            TableColumn("") { _ in Toggle("", isOn: $vibrateOnRing )}.width(min: idealWidth, max: idealWidth)
            TableColumn("Address", value: \.addr).width(ideal: idealWidth)
            TableColumn("Raw Op", value: \.operation).width(ideal: idealWidth)
            TableColumn("Decoded Op", value: \.opcodeName).width(ideal: idealWidth)
         }
         .frame(minHeight: minRowHeight * 15)
         .cornerRadius(5)
      }.padding(5)
   }
}

struct RowData: Identifiable {
   let id = UUID()
   let name: String
   let value: String
}

struct RegisterView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   
   @ObservedObject var currentChip: Chip8
   
   var body: some View {
      GroupBox() {
         Table {
            TableColumn("Name") { Text($0.name) }.width(ideal: 15)
            TableColumn("Value") { Text($0.value) }
         } rows: {
            TableRow(RowData(name: "I",
                             value: String(format: "0x%04X", currentChip.I)));
            TableRow(RowData(name: "PC",
                             value: String(format: "0x%04X", currentChip.PC)));
            TableRow(RowData(name: "SP",
                             value: String(format: "0x%04X", currentChip.SP)));
            ForEach(0..<currentChip.registers.array.count, id: \.self) {
               TableRow(RowData(name: String(format: "V%01X", $0),
                                value: String(format: "0x%02X", currentChip.registers.array[$0])))
            }
         }
         .frame(height: minRowHeight * 15)
         .cornerRadius(5)
      }.padding(5)
   }
}
