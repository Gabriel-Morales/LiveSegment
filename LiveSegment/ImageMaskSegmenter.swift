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
    
    public var selectedImgUrl: URL?
    private var imageTranformCache = [URL:CIImage]()
    
    override init() {
        super.init()
    }
    
    override func applyFilter() -> CVPixelBuffer? {
        
        guard let uploadedImageUrl = selectedImgUrl else {
            return pixelBuffer
        }
        
        let mask = predictOnFrame()
        
        guard let alphaMatte = mask else {
            return nil
        }
    
        let selectedImg: CIImage?
        
        if imageTranformCache[uploadedImageUrl] == nil {
            selectedImg = tranformUploadedImage(withUploadedImageUrl: uploadedImageUrl)
            imageTranformCache[uploadedImageUrl] = selectedImg
        } else {
            selectedImg = imageTranformCache[uploadedImageUrl]
        }
        
        
        guard let unwrappedSelectedImage = selectedImg else {
            return nil
        }
        
        let resultImg = overlayMask(withMask: alphaMatte, andBackgroundImage: unwrappedSelectedImage)
        
        return createPixelBufferFromImage(withImage: resultImg)
    }
    
    private func tranformUploadedImage(withUploadedImageUrl uploadedImageUrl: URL) -> CIImage? {
     
        let uploadedImage = CIImage(contentsOf: uploadedImageUrl)!
        
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
