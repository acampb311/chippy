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
   @State private var image: Image?
   
   var body: some View {
      NavigationView {
         ScrollView {
            RomView(currentChip: self.$chip8)

            Button(action: {
               chip8.step(chip: &chip8)
               image = chip8.display.ToImage()
            }) {Image(systemName: "play")}
            
            RegisterView(currentChip: self.$chip8)
            ConfigurationView(currentChip: self.$chip8)
            KeyboardView(currentChip: self.$chip8)
         }
         SpriteView(scene: chip8.newDisplay)
            .frame(width: 640, height: 320)
         
//
//            .scaledToFit()
//         image?
//            .resizable()
//            .scaledToFit()
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
}


struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView()
   }
}

//https://stackoverflow.com/questions/31661023/change-color-of-certain-pixels-in-a-uiimage
struct RGBA32: Equatable {
   private var color: UInt32
   
   var redComponent: UInt8 {
      return UInt8((color >> 24) & 255)
   }
   
   var greenComponent: UInt8 {
      return UInt8((color >> 16) & 255)
   }
   
   var blueComponent: UInt8 {
      return UInt8((color >> 8) & 255)
   }
   
   var alphaComponent: UInt8 {
      return UInt8((color >> 0) & 255)
   }
   
   init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
      let red   = UInt32(red)
      let green = UInt32(green)
      let blue  = UInt32(blue)
      let alpha = UInt32(alpha)
      color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
   }
   
   static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
   static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
   static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
   static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
   static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
   static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
   static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
   static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
   
   static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
   
   static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
      return lhs.color == rhs.color
   }
}

//https://rethunk.medium.com/convert-between-nsimage-and-ciimage-in-swift-d6c6180ef026
extension NSImage {
   /// Generates a CIImage for this NSImage.
   /// - Returns: A CIImage optional.
   func ciImage() -> CIImage? {
      guard let data = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: data) else {
         return nil
      }
      let ci = CIImage(bitmapImageRep: bitmap)
      return ci
   }
   
   /// Generates an NSImage from a CIImage.
   /// - Parameter ciImage: The CIImage
   /// - Returns: An NSImage optional.
   static func fromCIImage(_ ciImage: CIImage) -> NSImage {
      let rep = NSCIImageRep(ciImage: ciImage)
      let nsImage = NSImage(size: rep.size)
      nsImage.addRepresentation(rep)
      return nsImage
   }
}
