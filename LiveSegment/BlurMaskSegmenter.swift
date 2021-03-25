//
//  BlurMaskSegmenter.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/23/21.
//

import Foundation
import CoreImage.CIFilter

class BlurMaskSegmenter: SegmentedRenderer {
    
    private let guassianFilter = CIFilter(name: "CIGaussianBlur")
    public var radiusLevel: Float = 5
    
    override init() {
        super.init()
    }
    
    override func applyFilter() -> CVPixelBuffer? {
        
        let mask = predictOnFrame()
        
        guard let alphaMatte = mask else {
            return nil
        }
        
        return blurBackGroundWithMask(mask: alphaMatte)
    }
    
    private func blurBackGroundWithMask(mask alphaMatte: CIImage) -> CVPixelBuffer? {
            
        guard let buffer = pixelBuffer else {
            return nil
        }

        var backgroundImage = CIImage(cvImageBuffer: buffer)
        
        guassianFilter?.setValue(backgroundImage, forKey: "inputImage")
        guassianFilter?.setValue(radiusLevel, forKey: "inputRadius")
        backgroundImage = guassianFilter!.outputImage!
        
        
        let outputImage = overlayMask(withMask: alphaMatte, andBackgroundImage: backgroundImage)
        let resultPixelBuffer = createPixelBufferFromImage(withImage: outputImage)
        
        
        return resultPixelBuffer
    }
    
}
