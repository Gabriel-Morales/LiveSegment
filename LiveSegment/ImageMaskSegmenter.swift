//
//  imageMaskSegmenter.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/23/21.
//

import Foundation
import CoreVideo
import CoreImage

class ImageMaskSegmenter: SegmentedRenderer {
    
    public var selectedImg: CIImage?
    
    override init() {
        super.init()
    }
    
    override func applyFilter() -> CVPixelBuffer? {
        
        guard var uploadedImage = selectedImg else {
            return pixelBuffer
        }
        
        let mask = predictOnFrame()
        
        guard let alphaMatte = mask else {
            return nil
        }
    
        selectedImg = tranformUploadedImage(withUploadedImae: uploadedImage)
        
        let resultImg = overlayMask(withMask: alphaMatte, andBackgroundImage: uploadedImage)
        
        return createPixelBufferFromImage(withImage: resultImg)
    }
    
    private func tranformUploadedImage(withUploadedImae uploadedImage: CIImage) -> CIImage? {
     
        
        let imgWidth = CVPixelBufferGetWidth(pixelBuffer!)
        let imgHeight = CVPixelBufferGetHeight(pixelBuffer!)
        
        let uploadedImgWidth = uploadedImage.extent.width
        let uploadedImgHeight = uploadedImage.extent.height
        
        let xScale = CGFloat(imgWidth) / CGFloat(uploadedImgWidth)
        let yScale = CGFloat(imgHeight) / CGFloat(uploadedImgHeight)
        
        let scaleTransform = CGAffineTransform(scaleX: xScale, y: yScale)
        
        return uploadedImage.transformed(by: scaleTransform)
        
    }
    
}
