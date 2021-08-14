//
//  Display.swift
//  chippy
//
//  Created by Adam Campbell on 8/7/21.
//

import Foundation
import SwiftUI

struct Pixel {
    var offset: Int
    var color: RGBA32
}

struct Display {
    var width: Int
    var height: Int
    var context: CGContext?
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    var bitmapData: UnsafeMutableRawPointer?
    var bitmapByteCount: Int
    var bitmapBytesPerRow: Int
    var currDisplay: CGImage?
    
    var pixelBuffer: UnsafeMutablePointer<RGBA32>?
    var size: NSSize = NSSize(width: 0, height: 0)
    
    init(pixelsWide: Int, pixelsHigh: Int) {
        self.width = pixelsWide
        self.height = pixelsHigh
        self.bitmapBytesPerRow = (pixelsWide * 4)
        self.bitmapByteCount = (bitmapBytesPerRow * pixelsHigh)
        self.size = NSSize(width: pixelsWide, height: pixelsHigh)
        bitmapData = UnsafeMutableRawPointer.allocate(byteCount: self.bitmapByteCount, alignment: 1)
        
        guard let bitmapData = bitmapData else {
            print("Display:init() Memory not allocated!")
            return
        }
        
        pixelBuffer = bitmapData.bindMemory(to: RGBA32.self, capacity: width * height)
        
        guard pixelBuffer != nil else {
            print("Display:init() Memory not allocated!")
            return
        }
        
        context = CGContext(data: bitmapData, width: self.width, height: self.height, bitsPerComponent: 8, bytesPerRow: self.bitmapBytesPerRow, space: self.colorSpace, bitmapInfo: self.bitmapInfo)
        
        DrawCurrentBitmap()
    }
    
    mutating func DrawCurrentBitmap() {
        if let myContext = context {
            currDisplay = myContext.makeImage()
        } else {
            print("Display:init() Context not created!")
            return
        }
    }
    
    mutating func DrawPixels(pixels: [Pixel]) -> Bool {
        var pixelAlreadySet = false
        
        for pixel in pixels {
            if let pixelBuffer = pixelBuffer {
                if (pixelBuffer[pixel.offset] == pixel.color) {
                    pixelAlreadySet = true
                }
                
                pixelBuffer[pixel.offset] = pixel.color
            }
        }
        
        DrawCurrentBitmap()
        
        return pixelAlreadySet
    }
    
    func ToImage() -> Image {
        return Image(nsImage: NSImage(cgImage: self.currDisplay!, size: self.size)).interpolation(.none)
    }
    
    mutating func Clear() {
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                pixelBuffer![offset] = .black
            }
        }
        
        DrawCurrentBitmap()
    }
}
