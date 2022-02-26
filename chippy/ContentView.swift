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
            RegisterView(pc: $chip8.visPC, i: $chip8.visI, sp: $chip8.visSP, dt: $chip8.visDT, st: $chip8.visST)
            
            HStack {
               GeneralRegisterView(vx: $chip8.visVx)
               StackView(stack: $chip8.visStack)
            }.padding(0)
            
            InstrView(allInstructions: $chip8.allInstructions)
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
   chip8.running = false
}

func StartChipTimers(chip8: Chip8) {
   DispatchQueue.global(qos: .background).async {
      chip8.running = true
      chip8.go()
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

struct InstrView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight

   @State private var idealWidth: CGFloat = 20
   @Binding var allInstructions: [InstructionInfo]
   
   var body: some View {
      GroupBox() {
         Table($allInstructions) {
            TableColumn("") { Toggle("", isOn: $0.breakHere ) }.width(min: idealWidth, max: idealWidth)
            TableColumn("Address") { Text( String(format: "0x%04X", $0.address.wrappedValue) )}.width(ideal: idealWidth)
            TableColumn("Raw Op") { Text( String(format: "0x%04X", $0.instruction.wrappedValue) )}.width(ideal: idealWidth)
            TableColumn("Decoded Op", value: \.description.wrappedValue)
         }.frame(minHeight: minRowHeight * 15)
      }.padding(5)
   }
}

struct Register: View {
   let name: String
   let value: String
   
   var body: some View {
      HStack(alignment: .center, spacing: nil) {
         Text("\(name)")
            .frame(maxWidth: 30, alignment: .leading)
         Divider()
         Text("\(value)")
            .frame(alignment: .leading)
      }
   }
}

struct RegisterView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   
   @Binding var pc: String
   @Binding var i: String
   @Binding var sp: String
   @Binding var dt: String
   @Binding var st: String
   
   var body: some View {
      GroupBox() {
         List {
            Register(name: "PC", value: pc)
            Register(name: "I", value: i)
            Register(name: "SP", value: sp)
            Register(name: "DT", value: dt)
            Register(name: "ST", value: st)
         }
         .frame(minHeight: minRowHeight * 6)
         .listStyle(.inset(alternatesRowBackgrounds: true))
         .cornerRadius(5)
      }.padding(5)
   }
}

struct StackView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   
   @Binding var stack: [UInt16]
   
   var body: some View {
      GroupBox() {
         List(stack.indices, id: \.self) { idx in
            Register(name: String(format: "SP%01X", idx), value: String(format: "0x%04X", stack[idx]))
         }
         .frame(minHeight: minRowHeight * 15)
         .listStyle(.inset(alternatesRowBackgrounds: true))
         .cornerRadius(5)
      }.padding(5)
   }
}

struct GeneralRegisterView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   
   @Binding var vx: [UInt8]
   
   var body: some View {
      GroupBox() {
         List(vx.indices, id: \.self) { idx in
            Register(name: String(format: "V%01X", idx), value: String(format: "0x%02X", vx[idx]))
         }
         .frame(minHeight: minRowHeight * 15)
         .listStyle(.inset(alternatesRowBackgrounds: true))
         .cornerRadius(5)
      }.padding(5)
   }
}

