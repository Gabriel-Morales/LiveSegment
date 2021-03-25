//
//  AVMetalPreviewView.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/12/21.
//

import Foundation
import MetalKit
import AVFoundation
import Vision

class AVMetalPreviewView: MTKView  {

    private let metalHelper: MetalResourceHelper = MetalResourceHelper.getInstance()
    
    private var commandQueue: MTLCommandQueue?
    private var mtllibrary: MTLLibrary?
    private var pipelinedescriptor: MTLRenderPipelineDescriptor?
    private var pipelinestate: MTLRenderPipelineState?
    private var samplerDescriptor: MTLSamplerDescriptor?
    private var samplerState: MTLSamplerState?
    
    private var textureCache: CVMetalTextureCache?
    private var internalPixelBuffer: CVPixelBuffer?
    
    private var vertexFunction: MTLFunction?
    private var fragmentFunction: MTLFunction?
    
    private let bufferPermits = DispatchSemaphore(value: 3)
    
    private let predictionQueue = DispatchQueue(label: "Prediction Queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem)
    
    private var vertexBuffer: MTLBuffer?
    private var textureBuffer: MTLBuffer?
    
    private var filteringEnabled: Bool = false

    public var isFilteringEnabled: Bool {
        get {
            return filteringEnabled
        }
        
        set {
            filteringEnabled = newValue
        }
    }

    var pixelBuffer: CVPixelBuffer? {
        set {
            self.internalPixelBuffer = newValue
        }
        
        get {
            return self.internalPixelBuffer
        }
    }
    
    required init(coder: NSCoder) {
        
        super.init(coder: coder)
        
        setupMetal()
        
        generateVertexBuffer()
        generateTextureBuffer()
    }
    
    private func setupMetal() {
        
        colorPixelFormat = metalHelper.defaultColorFormat
        device = metalHelper.getDefaultMetalDevice()
        
        commandQueue = metalHelper.getCommandQueue()
        mtllibrary = metalHelper.getDefaultLibrary()
        
        metalHelper.setShaderFunctions(vertexFunctionName: "vertexPassthroughShader",
                                       fragmentFunctionName: "fragmentPassthroughShader")
    
        vertexFunction = metalHelper.getVertexFunction()
        fragmentFunction = metalHelper.getFragmentFunction()
        
        (pipelinedescriptor, pipelinestate) = metalHelper.getRenderPipeline()
        (samplerDescriptor, samplerState) = metalHelper.getSampler()
        
    }
    
    private func generateVertexBuffer() {
        let vertexData = generateVertexData()
        let vertexBuffer = device!.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.stride)
        self.vertexBuffer = vertexBuffer
    }
    
    private func generateTextureBuffer() {
        let textureData = generateTextureData()
        let textureBuffer = device!.makeBuffer(bytes: textureData, length: textureData.count * MemoryLayout<Float>.stride)
        self.textureBuffer = textureBuffer
    }
    
    private func generateVertexData() -> [Float] {
        
        // (X,Y) = normalized coordinates
        // (-1, 1) = top left
        // (1, 1) = top right
        // (-1, -1) = bottom left
        // (1, -1) = bottom right
        
        // X,Y,Z, W - (normalization factor)
        let vertexData: [Float] = [-1, 1, 0, 1, // top left
                                   -1, -1, 0, 1, // top right
                                    1, 1, 0, 1, // bottom left
                                    1, -1, 0, 1] // bottom right vertex
        
        return vertexData
    }
    
    private func generateTextureData() -> [Float] {
        

        let texData: [Float] =  [1, 0,
                                 1, 1,
                                 0, 0,
                                 0, 1]
        return texData
        
    }
    
    override func draw(_ rect: NSRect) {

        guard let pipelineState = pipelinestate else {
            return
        }
        
        guard let samplerState = samplerState else {
            return
        }

        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            NSLog("Failed to setup command buffer")
            releaseResources()
            return
        }
        
        guard let pixBuff = pixelBuffer else {
            return
        }
        
        let bufferHeight = CVPixelBufferGetHeight(pixBuff)
        let bufferWidth = CVPixelBufferGetWidth(pixBuff)

        bufferPermits.wait()

        commandBuffer.addCompletedHandler({ (Void) -> Void in
            self.bufferPermits.signal()
        })
        
        guard let screenDescriptor = currentRenderPassDescriptor, let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: screenDescriptor) else {
            
            print("Failed to obtain render descriptor or encoder.")
            releaseResources()
            return
        }
  
        commandEncoder.setRenderPipelineState(pipelineState)
           
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
  
        
        initializeTextureCache()
        
        var cvMetalOutputTexture: CVMetalTexture?
        createCVMetalTexture(bufferWidth, bufferHeight, &cvMetalOutputTexture, pixBuff)
            
        let metalTexture = CVMetalTextureGetTexture(cvMetalOutputTexture!)
        commandEncoder.setFragmentTexture(metalTexture, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
        commandEncoder.endEncoding()
            
        guard let drawable = currentDrawable else {
            releaseResources()
            return
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()

    }
    
    private func createCVMetalTexture(_ bufferWidth: Int, _ bufferHeight: Int, _ cvMetalOutputTexture: inout CVBuffer?, _ pixBuff: CVPixelBuffer) {
        
        let error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, pixBuff, nil, colorPixelFormat, bufferWidth, bufferHeight, 0, &cvMetalOutputTexture)
        
        if error == kCVReturnError {
            print("Error creating CV Metal texture from buffer.")
        }
        
    }
    
    private func initializeTextureCache() {
        
        var error: CVReturn? = nil
        
        if textureCache == nil {
            error = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &textureCache)
        }
        
        if (textureCache == nil) && (error! == kCVReturnError) {
            print("Error creating texture cache.")
        }
    }
    
    private func releaseResources() {
        CVMetalTextureCacheFlush(textureCache!, CVOptionFlags(0))
        pixelBuffer = nil
    }
    
    
    
}
