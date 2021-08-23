//
//  ContentView.swift
//  chippy
//
//  Created by Adam Campbell on 7/15/21.
//

import SwiftUI
import SpriteKit

struct ContentView : View {
   @State private var chip8 = Chip8()
   
   var body: some View {
      NavigationView {
         ScrollView {
            RomView(currentChip: self.$chip8)

            Button(action: {
               chip8.step(chip: &chip8)
            }) {Image(systemName: "play")}
            
            RegisterView(currentChip: self.$chip8)
            ConfigurationView(currentChip: self.$chip8)
            KeyboardView(currentChip: self.$chip8)
         }
         SpriteView(scene: chip8.display)
            .frame(width: 640, height: 320)
      }
   }
}

struct RomView: View {
   @Binding var currentChip: Chip8

   @State var filename = "Filename"
   @State var showFileChooser = false
   
   var body: some View {
      HStack {
         Text(filename)
         Button("select File")
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
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
}

struct ConfigurationView : View {
   @Binding var currentChip: Chip8
   @State private var bgColor =
      Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var body: some View {
      
      DisclosureGroup(
         content: {
            VStack {
               ColorPicker("Alignment Guides", selection: $bgColor)
            }
         },
         label: {
            HStack(spacing: 5) {
               Image(systemName: "switch.2")
               Text("Configuration")
            }
         })
         .padding([.top, .leading, .trailing], 10.0)
   }
}

struct KeyboardView : View {
   @Binding var currentChip: Chip8
   
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var body: some View {
      DisclosureGroup(
         content: {
         },
         label: {
            HStack(spacing: 5) {
               Image(systemName: "keyboard")
               Text("Keyboard")
            }
         })
         .padding([.top, .leading, .trailing], 10.0)
   }
}

struct RegisterView : View {
   @Binding var currentChip: Chip8
   
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var body: some View { DisclosureGroup(
      content: {
         LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: 5
         ) {
            ForEach((0...(currentChip.registers.count) - 1), id: \.self) {  i in
               HStack {
                  Text("V\(String(format:"%01x", i).uppercased()):")
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
