//
//  ContentView.swift
//  chippy
//
//  Created by Adam Campbell on 7/15/21.
//

import SwiftUI
import SpriteKit
import Combine

class TimerWrapper : ObservableObject {
   let willChange = PassthroughSubject<TimerWrapper, Never>()
   @Published var timer : Timer!
   
   func start(withTimeInterval interval: Double) {
      self.timer?.invalidate()
      self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
         self.willChange.send(self)
      }
   }
}

struct ContentView : View {
   
   @State private var chip8 = Chip8()
   @State var timer = Timer.publish(every: 1.0, on: .main, in: .default).autoconnect()

   @State private var freq: Double = 100
   
   private let delayTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

   var body: some View {
      
      NavigationView {
         ScrollView {
            Slider(value: $freq, in: 100...100000).onChange(of: freq) { _ in
               self.timer = Timer.publish(every: 1/freq, on: .main, in: .default).autoconnect()
            }
            
            RomView(currentChip: self.$chip8)
            RegisterView(currentChip: self.$chip8)
            ConfigurationView(currentChip: self.$chip8)
         }
         
         SpriteView(scene: chip8.display)
            .frame(width: 640, height: 320)
      }.onReceive(self.timer) { _ in
         chip8.step(chip: &chip8)
      }.onReceive(delayTimer) { t in
         if (chip8.DT > 0)
         {
            chip8.DT-=1
         }
      }.background(KeyEventHandling(currentChip: self.$chip8))
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
   @Binding var currentChip: Chip8
   
   var columns: [GridItem] = [
      GridItem(.adaptive(minimum: 50))
   ]
   
   var someNumberProxy: Binding<String> {
      Binding<String>(
         get: { String(format: "%01x", currentChip.I) },
         set: {
            if let value = NumberFormatter().number(from: $0) {
               currentChip.I = UInt16(truncating: value)
            }
         }
      )
   }
   
   var body: some View {
      
      DisclosureGroup(
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
                  TextField("", text: someNumberProxy)
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

//https://stackoverflow.com/questions/61153562/how-to-detect-keyboard-events-in-swiftui-on-macos
struct KeyEventHandling: NSViewRepresentable {
   @Binding var currentChip: Chip8
   
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
