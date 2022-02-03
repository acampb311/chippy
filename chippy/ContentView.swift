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
      chip8.gameTimer = Timer(timeInterval: 1/1000, target: chip8, selector: #selector(chip8.Step), userInfo: nil, repeats: true)
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
               currentChip.LoadRom(rom: rom)
               self.filename = url.lastPathComponent
               url.stopAccessingSecurityScopedResource()
            }
         }
      }.padding(5)
   }
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
         Table($currentChip.allInstructions) {
            TableColumn("") { Toggle("", isOn: $0.breakHere ) }.width(min: idealWidth, max: idealWidth)
            TableColumn("Address") { Text( String(format: "0x%04X", $0.address.wrappedValue) )}.width(ideal: idealWidth)
            TableColumn("Raw Op") { Text( String(format: "0x%04X", $0.instruction.wrappedValue) )}.width(ideal: idealWidth)
            TableColumn("Decoded Op", value: \.description.wrappedValue)
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
