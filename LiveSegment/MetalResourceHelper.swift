//
//  MetalSetupHelper.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/20/21.
//

import Foundation
import MetalKit

class MetalResourceHelper {
    
    private static var instance: MetalResourceHelper?

    private var mtldevice: MTLDevice?
    private var mtllibrary: MTLLibrary?
    
    private var commandQueue: MTLCommandQueue?
    
    private var pipelinedescriptor: MTLRenderPipelineDescriptor?
    private var pipelinestate: MTLRenderPipelineState?
    
    private var samplerDescriptor: MTLSamplerDescriptor?
    private var samplerState: MTLSamplerState?
    
    private var vertexFunction: MTLFunction?
    private var fragmentFunction: MTLFunction?
    
    private var textureDescriptor: MTLTextureDescriptor?
    
    public var defaultColorFormat: MTLPixelFormat {
        return .bgra8Unorm
    }
    
    private init() {
        
        setupMetalDevice()
        setupCommandQueue()
        setupDefaultLibrary()
        setupSampler()
        setupTextureDescriptor()
        
    }
    
    private func setupTextureDescriptor() {
        
        self.textureDescriptor = MTLTextureDescriptor()
        
        guard let _ = textureDescriptor else {
            print("Texture descriptor setup failed.")
            return
        }
        
        self.textureDescriptor?.resourceOptions = .storageModePrivate
        self.textureDescriptor?.usage = .shaderRead
    }
    
    private func setupMetalDevice() {
        
        self.mtldevice = MTLCreateSystemDefaultDevice()
        
        guard let _ = self.mtldevice else {
            print("Default device setup failed!")
            return
        }
        
    }
    
    private func setupCommandQueue() {
        guard let defaultDevice = self.mtldevice else {
            print("Cannot use nil default dvice for command queue.")
            return
        }
        
        self.commandQueue = defaultDevice.makeCommandQueue()
    }
    
    private func setupDefaultLibrary() {
        guard let defaultDevice = self.mtldevice else {
            print("Cannot use nil default device for default library!")
            return
        }
        
        self.mtllibrary = defaultDevice.makeDefaultLibrary()
    }
    
    public func setShaderFunctions(vertexFunctionName vName: String, fragmentFunctionName fName: String) {
        setVertexFunction(functionName: vName)
        setFragmentFunction(functionName: fName)
        setupRenderPipeline()
    }
    
    private func setVertexFunction(functionName name: String) {
        guard let defaultLibrary = self.mtllibrary else {
            print("Cannot use nil default library for vertex functions!")
            return
        }
        
        self.vertexFunction = defaultLibrary.makeFunction(name: name)
    }
    
    private func setFragmentFunction(functionName name: String) {
        guard let defaultLibrary = self.mtllibrary else {
            print("Cannot use nil default library for fragment functions!")
            return
        }
        
        self.fragmentFunction = defaultLibrary.makeFunction(name: name)
    }
    
    
    private func setupRenderPipeline() {
        
        guard let device = mtldevice else {
            print("Cannot setup render pipeline without a proper device!")
            return
        }
        
        self.pipelinedescriptor = MTLRenderPipelineDescriptor()
        
        guard let pDescriptor = self.pipelinedescriptor else {
            print("Failed to setup pipeline.")
            return
        }
        
        pDescriptor.vertexFunction = vertexFunction
        pDescriptor.fragmentFunction = fragmentFunction
        pDescriptor.colorAttachments[0].pixelFormat = defaultColorFormat
        
        do {
            self.pipelinestate = try device.makeRenderPipelineState(descriptor: pDescriptor)
        } catch {
            print("Failed to setup pipeline.")
            return
        }
    }
    
    private func setupSampler() {
        
        guard let device = mtldevice else {
            print("Cannot setup render pipeline without a proper device!")
            return
        }
        
        self.samplerDescriptor = MTLSamplerDescriptor()
        
        guard let sDescriptor = self.samplerDescriptor else {
            print("Failed setting up sampler.")
            return
        }
        
        sDescriptor.rAddressMode = .clampToEdge
        sDescriptor.sAddressMode = .clampToEdge
        sDescriptor.minFilter = .linear
        sDescriptor.magFilter = .linear
        
        self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor!)
    }
    
    
    // getter functions
    
    public static func  getInstance() -> MetalResourceHelper {
        
        if instance == nil {
            instance = MetalResourceHelper()
        }
        
        return instance!
    }
    
    public func getDefaultMetalDevice() -> MTLDevice? {
        return self.mtldevice
    }
    
    public func getCommandQueue() -> MTLCommandQueue? {
        return self.commandQueue
    }
    
    public func getDefaultLibrary() -> MTLLibrary? {
        return self.mtllibrary
    }
    
    public func getVertexFunction() -> MTLFunction? {
        return self.vertexFunction
    }
    
    public func getFragmentFunction() -> MTLFunction? {
        return self.fragmentFunction
    }
    
    public func getRenderPipeline() -> (MTLRenderPipelineDescriptor?, MTLRenderPipelineState?) {
        return (self.pipelinedescriptor, self.pipelinestate)
    }
    
    public func getSampler() -> (MTLSamplerDescriptor?, MTLSamplerState?) {
        return (self.samplerDescriptor, self.samplerState)
    }
    
    public func getTextureDecriptor() -> MTLTextureDescriptor? {
        return self.textureDescriptor
    }
    
}
