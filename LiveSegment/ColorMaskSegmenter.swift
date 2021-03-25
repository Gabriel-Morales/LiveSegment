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
    
    public var colorChoice: NSColor? = NSColor.black
    private var priorNSColor: NSColor?
    private var colorCache = [NSColor:CIImage]()
    private let MAX_CACHE_SIZE = 10
    
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
        
        if colorCache.count == MAX_CACHE_SIZE {
            flushColorCache()
        }
        
        let ciColorImg: CIImage?
        
        if ((priorNSColor == colorChoice) && (colorCache[colorChoice!] != nil)) || colorCache[colorChoice!] != nil {
            ciColorImg = colorCache[colorChoice!]
        } else {
            priorNSColor = colorChoice
            let ciColor = CIColor(color: color)
            
            guard let color = ciColor else {
                return nil
            }
            
            ciColorImg = CIImage(color: color)
            colorCache[colorChoice!] = ciColorImg!
        }
        
        if let applyColor = ciColorImg {
            let resultImg = overlayMask(withMask: alphaMatte, andBackgroundImage: applyColor)
            
            return createPixelBufferFromImage(withImage: resultImg)
        }
        
        return nil
        
    }
    
    
    private func flushColorCache() {
        colorCache.removeAll()
    }
    
}
