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
   
   @State var showInspector = true
   @State var showControls = true
   
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
   DispatchQueue.global(qos: .userInteractive).async {
      chip8.gameTimer = Timer(timeInterval: 1/300, target: chip8, selector: #selector(chip8.Step), userInfo: nil, repeats: true)
      //         RunLoop.current.add(chip8.gameTimer!, forMode: .common)
      let runLoop = RunLoop.current
      runLoop.add(chip8.gameTimer!, forMode: .default)
      runLoop.run()
      
   }
   DispatchQueue.global(qos: .userInteractive).async {
      chip8.delayTimer = Timer(timeInterval: 1/60, target: chip8, selector: #selector(chip8.delayStep), userInfo: nil, repeats: true)
      //   RunLoop.current.add(chip8.delayTimer!, forMode: .common)
      let runLoop = RunLoop.current
      runLoop.add(chip8.delayTimer!, forMode: .default)
      runLoop.run()
   }
}

struct RomView: View {
   @ObservedObject var currentChip: Chip8
   @State private var filename = "ROM"
   @State private var showImporter = false
   
   var body: some View {
      HStack {
         Text(filename)
         Button("Select ROM") {
            self.showImporter = true
         }
         .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            if let url = try? result.get(),
               url.startAccessingSecurityScopedResource(),
               let rom = try? [UInt8](Data(contentsOf: url))
            {
               currentChip.loadRom(rom: rom)
               self.filename = url.lastPathComponent
               url.stopAccessingSecurityScopedResource()
            }
         }
      }.padding(5)
   }
}

struct RowInstructionInfo: Identifiable {
   let id = UUID()
   let address: String
   let instruction: String
   let description: String
   let breakpoint: Binding<Bool>
}

struct RowRegisterInfo: Identifiable {
   let id = UUID()
   let name: String
   let value: String
}


struct InstrView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   @ObservedObject var currentChip: Chip8
   @State private var idealWidth: CGFloat = 20
   
   var body: some View {
      GroupBox() {
         Table {
            TableColumn("") { Toggle("", isOn: $0.breakpoint ) }.width(min: idealWidth, max: idealWidth)
            TableColumn("Address") { Text($0.address) }.width(ideal: idealWidth)
            TableColumn("Raw Op") { Text($0.instruction) }.width(ideal: idealWidth)
            TableColumn("Decoded Op") { Text($0.description) }.width(ideal: idealWidth * 7)
         } rows: {
            ForEach($currentChip.allInstructions.indices) { i in
               TableRow(RowInstructionInfo(address: String(format: "0x%04X", currentChip.allInstructions[i].address),
                                           instruction:  String(format: "0x%04X", currentChip.allInstructions[i].instruction),
                                           description: currentChip.allInstructions[i].description,
                                           breakpoint: $currentChip.allInstructions[i].breakHere))
            }
         }.frame(minHeight: minRowHeight * 15)
      }.padding(5)
   }
}

struct RegisterView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   
   @ObservedObject var currentChip: Chip8
   
   var body: some View {
      GroupBox() {
         Table {
            TableColumn("Name") { Text($0.name) }
            TableColumn("Value") { Text($0.value) }
         } rows: {
            ForEach(currentChip.visibileData.keys, id: \.self) {
               TableRow(RowRegisterInfo(name: $0, value: currentChip.visibileData[$0] ?? ""))
            }
         }.frame(minHeight: minRowHeight * 15)
         .cornerRadius(5)
      }.padding(5)
   }
}
