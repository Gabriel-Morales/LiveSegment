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
    
    private var requestHandler: VNSequenceRequestHandler?
    private static var visionModel: VNCoreMLModel?
    
    public var cicontext: CIContext?
    
    private var buff: CVPixelBuffer?
    internal var bufferPool: CVPixelBufferPool?
    
    private var transpositionHistory = [CGPoint]()
    private var maxHistoryCount = 15
    
    private var priorMask: CIImage?
    
    public var pixelBuffer: CVBuffer? {
        get {
            return buff
        }
        set {
            buff = newValue
        }
    }
    
    
    init() {

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let baseModel = try DeepLabV3Int8Img(configuration: config)
            SegmentedRenderer.visionModel = try VNCoreMLModel(for: baseModel.model)
            requestHandler = VNSequenceRequestHandler()
            
        } catch {
            print("Unable to initialize vision renderer.")
        }

    }
    
    internal func predictOnFrame() -> CIImage? {
        
        guard let imagebuff = buff else {
            return nil
        }
        
        do {
            
            let translationalRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: imagebuff)
            try requestHandler!.perform([translationalRequest], on: imagebuff)
            
            if let successfulRequest = translationalRequest.results {
                
                let transposition = successfulRequest[0] as! VNImageTranslationAlignmentObservation
                let transform = transposition.alignmentTransform
      
                let tranformCoordinate = CGPoint(x: transform.tx, y: transform.ty)
                
                transpositionHistory.append(tranformCoordinate)
            }

            if sceneRedundancyStable() {
                return priorMask
            }
            
            if transpositionHistory.count >= maxHistoryCount {
                transpositionHistory.removeAll()
            }
            
            let visionRequest = VNCoreMLRequest(model: SegmentedRenderer.visionModel!)
            visionRequest.imageCropAndScaleOption = .scaleFill
            try requestHandler!.perform([visionRequest], on: imagebuff)
            
            let observations = visionRequest.results as? [VNPixelBufferObservation]
            
            if observations == nil {
                return nil
            }
            
            let maskBuff = observations![0].pixelBuffer
            
            let maskImage = CIImage(cvImageBuffer: maskBuff)
            
            let imgWidth = CVPixelBufferGetWidth(imagebuff)
            let imgHeight = CVPixelBufferGetHeight(imagebuff)
            
            let maskWidth = CVPixelBufferGetWidth(maskBuff)
            let maskHeight = CVPixelBufferGetHeight(maskBuff)

            let xScale = CGFloat(imgWidth) / CGFloat(maskWidth)
            let yScale = CGFloat(imgHeight) / CGFloat(maskHeight)
            
            let scaleTransform = CGAffineTransform(scaleX: xScale, y: yScale)

            var alphaMatte = maskImage
                .applyingFilter("CIColorThresholdOtsu")
                .applyingFilter("CIBoxBlur", parameters: ["inputRadius":3.5])

            alphaMatte = alphaMatte.transformed(by: scaleTransform)

            priorMask = alphaMatte
            
            return alphaMatte
            
        } catch {
            print("Prediction failed.")
        }
        
        return nil
    }
    
    internal func applyFilter() -> CVPixelBuffer? {
        preconditionFailure("Abstract method must be overriden.")
    }
    
    
    private func sceneRedundancyStable() -> Bool {
        
        // from https://developer.apple.com/documentation/vision/training_a_create_ml_model_to_classify_flowers
        // manhattan distabce between two points on a coordinate system.
        // if the distance average passes a threshold, this qualifies true/false
        
        // MD: | x_1 + x_2 | - | y_1 + y_2 |
        // current assumption: the points stem from the prior frame in the array.
        
        // enough frames have been collected to analyze distance change
        if transpositionHistory.count >= maxHistoryCount {
            var movementTotals: CGPoint = CGPoint.zero
            for coordinate in transpositionHistory {
                
                movementTotals.x += coordinate.x
                movementTotals.y += coordinate.y
                
            }
    
            let mDistance = abs(movementTotals.x) - abs(movementTotals.y)
            
            if mDistance < 20 {
                return true
            }
            
        }
            
        return false
    }
    
    internal func overlayMask(withMask mask: CIImage, andBackgroundImage backImage: CIImage) -> CIImage? {
        
        guard let imagebuff = buff else {
            return nil
        }
        
        let inputImage = CIImage(cvImageBuffer: imagebuff)
        var blendFilter = CIFilter(name: "CIBlendWithMask")
        
        blendFilter?.setValue(inputImage, forKey: "inputImage")
        blendFilter?.setValue(mask, forKey: "inputMaskImage")
        blendFilter?.setValue(backImage, forKey: "inputBackgroundImage")
        
        let outputImg = blendFilter?.outputImage
        blendFilter = nil
        
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
