//
//  ColorMaskSegmenter.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/23/21.
//

import Foundation
import CoreVideo
import Cocoa

class ColorMaskSegmenter: SegmentedRenderer {
    
    public var colorChoice: NSColor?
    
    override init() {
        super.init()
    }
    
    override func applyFilter() -> CVPixelBuffer? {
        
        guard let color = colorChoice else {
            return nil
        }
        
        let mask = predictOnFrame()
        
        guard let alphaMatte = mask else {
            return nil
        }
        
        if let ciColor = CIColor(color: color) {
        
            let backgroundImage = CIImage(color: ciColor)
            
            let resultImg = overlayMask(withMask: alphaMatte, andBackgroundImage: backgroundImage)
            
            return createPixelBufferFromImage(withImage: resultImg)
        }
        
        return nil
        
    }
    
}
