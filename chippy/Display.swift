//
//  Display.swift
//  chippy
//
//  Created by Adam Campbell on 8/7/21.
//

import Foundation
import SwiftUI
import SpriteKit

class Display : SKScene, ObservableObject {
   var pixels: [SKSpriteNode] = []
   var height: Int = 0
   var width: Int = 0
   var displayForegroundColor: NSColor = .white
   var displayBackgroundColor: NSColor = .black
   
   func createDisplay(pixelsWide: Int, pixelsHigh: Int) {
      self.height = pixelsHigh
      self.width = pixelsWide
      
      for y in 0..<pixelsHigh {
         for x in 0..<pixelsWide {
            let location = CGPoint(x: Double(x)+0.5, y: Double(y)+0.5)
            let box = SKSpriteNode(color: SKColor.black, size: CGSize(width: 1, height: 1))
            
            box.position = location
            pixels.append(box)
            addChild(box)
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
      var collision = false
      guard x < width, y < height else {
         print("bad num")
         return collision
      }
      
      if pixels[(height - 1 - y) * 64 + x].color == displayForegroundColor {
         collision = true
      }
      
      pixels[(height - 1 - y) * 64 + x].color = displayForegroundColor
      
      return collision
   }
   
   //   ┌──────────────────────────────┐
   //   │  (0,0)               (X-1,0) │
   //   │                              │
   //   │                              │
   //   │                              │
   //   │                              │
   //   │ (0,Y-1)             (X-1,Y-1)│
   //   └──────────────────────────────┘
   func clearPixel(x: Int, y: Int) {
      guard x < width, y < height else {
         print("bad num")
         return
      }
      
      pixels[(height - 1 - y) * 64 + x].color = displayBackgroundColor
   }
}
