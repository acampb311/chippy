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

struct ContentView : View {
   
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
               chip8.delayTimer?.invalidate() } ){
                  Label("Stop", systemImage: "stop.fill")
               }
            Button(action: {
               
//               chip8.gameTimer = Timer(timeInterval: 1/1000, target: chip8, selector: #selector(chip8.timerStep), userInfo: nil, repeats: true);
//               RunLoop.current.add(chip8.gameTimer!, forMode: .common)
//
//               chip8.delayTimer = Timer(timeInterval: 1/60, target: chip8, selector: #selector(chip8.delayStep), userInfo: nil, repeats: true)
//               RunLoop.current.add(chip8.delayTimer!, forMode: .common)
               
            }) {
               Label("Play", systemImage: "play.fill")
            }
            Button( action: { self.chip8.timerStep() }
            ) {
               Label("Record Progress", systemImage: "forward.fill")
            }
         }
         
         SpriteView(scene: chip8.display).frame(width: 640, height: 320)
         
      }.onAppear(perform: {self.chip8.currentChip = chip8}).background(KeyEventHandling(currentChip: self.chip8))
   }
}

struct RomView: View {
   @ObservedObject var currentChip: Chip8
   
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


struct InstrView : View {
   
   @Environment(\.defaultMinListRowHeight) var minRowHeight
   @ObservedObject var currentChip: Chip8
   
   var body: some View {
      
      DisclosureGroup(
         content: {
            VStack {
               
               List($currentChip.instrList,id:\.self) {$inst in Text(inst) }.frame(minHeight: minRowHeight * 15).border(Color.red)
            }
         },
         label: {
            HStack(spacing: 5) {
               Image(systemName: "switch.2")
               Text("gg")
            }
         }).padding([ .leading, .trailing], 10.0)
   }
}

struct ConfigurationView : View {
   @ObservedObject var currentChip: Chip8
   
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var body: some View {
      DisclosureGroup(
         content: {
            VStack {
               
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

struct RegisterView : View {
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

class HexFormatter: Formatter {
   override func string(for obj: Any?) -> String? {
      if let string = obj as? Int {
         return formattedAddress(mac: string)
      }
      return nil
   }
   
   override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
      obj?.pointee = string as AnyObject?
      return true
   }
   
   func formattedAddress(mac: Int?) -> String? {
      guard let number = mac else { return nil }
      
      return String(format:"%04X", number)
      
      
   }
}


//https://stackoverflow.com/questions/61153562/how-to-detect-keyboard-events-in-swiftui-on-macos
struct KeyEventHandling: NSViewRepresentable {
   @ObservedObject var currentChip: Chip8
   
   class KeyView: NSView {
      
      var tempChip: Chip8? = nil
      override var acceptsFirstResponder: Bool { true }
      override func keyDown(with event: NSEvent) {
         if let key = Int(event.charactersIgnoringModifiers ?? "", radix: 16) {
            tempChip?.SetKey(key: key)
         }
      }
      override func keyUp(with event: NSEvent) {
         if let key = Int(event.charactersIgnoringModifiers ?? "", radix: 16) {
            tempChip?.ClearKey(key: key)
         }
      }
   }
   
   func makeNSView(context: Context) -> NSView {
      let view = KeyView()
      view.tempChip = currentChip
      DispatchQueue.main.async { // wait till next event cycle
         view.window?.makeFirstResponder(view)
      }
      return view
   }
   
   func updateNSView(_ nsView: NSView, context: Context) {
   }
}
