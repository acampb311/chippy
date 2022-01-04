//
//  Display.swift
//  chippy
//
//  Created by Adam Campbell on 8/7/21.
//

import Foundation
import SwiftUI
import SpriteKit

struct Pixel {
   var node: SKSpriteNode?
   var set: Bool
}

public class Display : SKScene, ObservableObject {
   var pixels: [Pixel] = []
   
   public var height: Int = 0
   public var width: Int = 0
   var displayForegroundColor: NSColor = .white
   var displayBackgroundColor: NSColor = .black
   
   func createDisplay(pixelsWide: Int, pixelsHigh: Int) {
      self.height = pixelsHigh
      self.width = pixelsWide
      
      for y in 0..<pixelsHigh {
         for x in 0..<pixelsWide {
            
            //+0.5 because it is with respect to center of 1x1 box
            let location = CGPoint(x: Double(x)+0.5, y: Double(y)+0.5)
            let box = SKSpriteNode(color: NSColor.black, size: CGSize(width: 1, height: 1))
            
            box.position = location
            addChild(box)
            pixels.append(Pixel(node: box, set: false))
         }
      }
   }
   
   //   ┌──────────────────────────────┐
   //   │  (0,0)               (X-1,0) │
   //   │                              │
   //   │                              │
   //   │                              │
   //   │                              │
   //   │ (0,Y-1)             (X-1,Y-1)│
   //   └──────────────────────────────┘
   func setPixel(x: Int, y: Int) -> Bool {
      return setPixelDetails(pixel: &pixels[(height - 1 - (y % height)) * width + (x % width)])
   }
   
   func setPixelDetails(pixel: inout Pixel) -> Bool {
      let collision = pixel.set
      
      pixel.set = !pixel.set
      
      pixel.node?.color = pixel.set ? displayForegroundColor : displayBackgroundColor
      
      return collision
   }
  
   func clear() {
      for (index, _) in pixels.enumerated() {
         pixels[index].set = false
         pixels[index].node?.color = displayBackgroundColor
      }
   }
}
