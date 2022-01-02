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
            RomView(currentChip: self.chip8)
            RegisterView(currentChip: self.chip8)
            InstrView(currentChip: self.chip8)
            
         }.toolbar {
            Button(action: {
               chip8.gameTimer?.invalidate();
               chip8.delayTimer?.invalidate() }) {
                  Label("Stop", systemImage: "stop.fill")
               }
            Button(action: {
               
               chip8.gameTimer = Timer(timeInterval: 1/1000, target: chip8, selector: #selector(chip8.Step), userInfo: nil, repeats: true);
               RunLoop.current.add(chip8.gameTimer!, forMode: .common)
               
               chip8.delayTimer = Timer(timeInterval: 1/60, target: chip8, selector: #selector(chip8.delayStep), userInfo: nil, repeats: true)
               RunLoop.current.add(chip8.delayTimer!, forMode: .common)
               
            }) {
               Label("Play", systemImage: "play.fill")
            }
            Button(action: { self.chip8.Step() }
            ) {
               Label("Record Progress", systemImage: "forward.fill")
            }
         }
         
         SpriteView(scene: chip8.display).frame(width: 640, height: 320)
         
      }.onAppear(perform: { self.chip8.currentChip = chip8 })
   }
}

struct RomView: View {
   @ObservedObject var currentChip: Chip8
   
   @State var filename = "Filename"
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
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
   }
}

struct InstrView: View {
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   @ObservedObject var currentChip: Chip8
   @State private var sortOrder = [KeyPathComparator(\InstructionInfo.addr)]
   @State private var vibrateOnRing = false
   
   var body: some View {
      DisclosureGroup(
         content: {
            
            Table(currentChip.allInstructions, selection: $currentChip.currentInstruction, sortOrder: $sortOrder) {
               TableColumn("Address", value: \.addr)
               TableColumn("Raw Op", value: \.operation)
               TableColumn("Decoded Op", value: \.opcodeName)
            }.frame(minHeight: minRowHeight * 15)
         },
         label: {
            HStack(spacing: 5) {
               Image(systemName: "switch.2")
               Text("Instructions")
            }
         }).padding([.leading, .trailing], 10.0)
   }
}

struct RegisterView: View {
   @ObservedObject var currentChip: Chip8
   
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var body: some View {
      
      DisclosureGroup(
         content: {
            LazyVGrid(
               columns: columns,
               alignment: .leading,
               spacing: 8
            ) {
               ForEach((0...(currentChip.registers.count) - 1), id: \.self) { i in
                  HStack {
                     Text("V\(String(format: "%01x", i).uppercased()):")
                     TextField("", value: $currentChip.registers[i], formatter: NumberFormatter())
                  }
               }
               HStack {
                  Text("I:")
                  TextField("", value: $currentChip.I, formatter: NumberFormatter())
               }
               HStack {
                  Text("PC:")
                  TextField("", value: $currentChip.PC, formatter: NumberFormatter())
               }
               HStack {
                  Text("SP:")
                  TextField("", value: $currentChip.SP, formatter: NumberFormatter())
               }
            }
         },
         label: {
            HStack(spacing: 5) {
               Image(systemName: "cpu")
               Text("Registers")
            }
         }).padding([.top, .leading, .trailing], 10.0)
   }
}
