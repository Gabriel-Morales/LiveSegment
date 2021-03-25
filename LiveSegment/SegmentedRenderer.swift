//
//  SegmentedRenderer.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/21/21.
//

import Cocoa
import Vision
import CoreFoundation
import CoreML
import CoreVideo
import CoreImage

class SegmentedRenderer {
    
    public let predictionSemaphore: DispatchSemaphore
    // TODO: Change request handler types to deal with frames.
    private let requestHandler: VNSequenceRequestHandler
    private static var visionRequest: VNCoreMLRequest?
    private static var visionModel: VNCoreMLModel?
    
    public var cicontext: CIContext?
    
    private var buff: CVPixelBuffer?
    internal var bufferPool: CVPixelBufferPool?
    
    private let blendFilter = CIFilter(name: "CIBlendWithMask")
    
    public var pixelBuffer: CVBuffer? {
        get {
            return buff
        }
        set {
            buff = newValue
        }
    }
    
    
    init() {
        
        predictionSemaphore = DispatchSemaphore(value: 1)
        requestHandler = VNSequenceRequestHandler()

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let baseModel = try DeepLabV3Int8Img(configuration: config)
            SegmentedRenderer.visionModel = try VNCoreMLModel(for: baseModel.model)
            SegmentedRenderer.visionRequest = VNCoreMLRequest(model: SegmentedRenderer.visionModel!)
            SegmentedRenderer.visionRequest!.imageCropAndScaleOption = .scaleFill
            
            
        } catch {
            print("Unable to initialize vision renderer.")
        }

    }
    
    internal func predictOnFrame() -> CIImage? {
        
        guard let imagebuff = buff else {
            return nil
        }
        
        do {
            try requestHandler.perform([SegmentedRenderer.visionRequest!], on: imagebuff)
            let observations = SegmentedRenderer.visionRequest!.results as? [VNPixelBufferObservation]
            
            if observations == nil {
                return nil
            }
            
            let maskBuff = observations![0].pixelBuffer
            
            
            let imgWidth = CVPixelBufferGetWidth(imagebuff)
            let imgHeight = CVPixelBufferGetHeight(imagebuff)
            
            let maskWidth = CVPixelBufferGetWidth(maskBuff)
            let maskHeight = CVPixelBufferGetHeight(maskBuff)

            let xScale = CGFloat(imgWidth) / CGFloat(maskWidth)
            let yScale = CGFloat(imgHeight) / CGFloat(maskHeight)
            
            let scaleTransform = CGAffineTransform(scaleX: xScale, y: yScale)

            let maskImage = CIImage(cvImageBuffer: maskBuff)
            let alphaMatte = maskImage.clampedToExtent()
                .applyingFilter("CIGammaAdjust", parameters: ["inputPower": 0.0007])
                .applyingFilter("CIGaussianBlur", parameters: ["inputRadius":1])
                //.applyingFilter("CIUnsharpMask", parameters: ["inputIntensity": 1.5, "inputRadius":8])
                .cropped(to: maskImage.extent)

            
            return alphaMatte.transformed(by: scaleTransform)
            
        } catch {
            print("Prediction failed.")
        }
        
        return nil
    }
    
    internal func applyFilter() -> CVPixelBuffer? {
        preconditionFailure("Abstract method must be overriden.")
    }
    
    
    internal func overlayMask(withMask mask: CIImage, andBackgroundImage backImage: CIImage) -> CIImage? {
        
        guard let imagebuff = buff else {
            return nil
        }
        
        let inputImage = CIImage(cvImageBuffer: imagebuff)

        blendFilter?.setValue(inputImage, forKey: "inputImage")
        blendFilter?.setValue(mask, forKey: "inputMaskImage")
        blendFilter?.setValue(backImage, forKey: "inputBackgroundImage")
        
        let outputImg = blendFilter?.outputImage
        
        return outputImg
    }
    
    internal func createPixelBufferFromImage(withImage image: CIImage?) -> CVPixelBuffer? {
        
        guard let buffer = pixelBuffer, let context = cicontext else {
            return nil
        }
        
        guard let outputImage = image else {
            return nil
        }
        
        
        let imgWidth = CVPixelBufferGetWidth(buffer)
        let imgHeight = CVPixelBufferGetHeight(buffer)
        
        
        var outPixelBuff: CVPixelBuffer?

        CVPixelBufferCreate(kCFAllocatorDefault, imgWidth, imgHeight, CVPixelBufferGetPixelFormatType(buffer), [kCVPixelBufferMetalCompatibilityKey:true] as CFDictionary, &outPixelBuff)
        
        
        guard let outPixBuff = outPixelBuff else {
            return nil
        }
        
        context.render(outputImage, to: outPixBuff)
        return outPixBuff
        
    }
    
}
