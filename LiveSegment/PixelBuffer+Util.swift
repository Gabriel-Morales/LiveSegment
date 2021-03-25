//
//  PixelBuffer+Util.swift
//  LiveSegment
//
//  Created by Gabriel Morales on 3/18/21.
//

import Foundation
import CoreVideo

extension CVPixelBuffer {
    
    func downscale(target_height: Int, target_width: Int) -> Void {
        
        
        
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, target_width, target_height, <#T##pixelFormatType: OSType##OSType#>, <#T##baseAddress: UnsafeMutableRawPointer##UnsafeMutableRawPointer#>, <#T##bytesPerRow: Int##Int#>, <#T##releaseCallback: CVPixelBufferReleaseBytesCallback?##CVPixelBufferReleaseBytesCallback?##(UnsafeMutableRawPointer?, UnsafeRawPointer?) -> Void#>, <#T##releaseRefCon: UnsafeMutableRawPointer?##UnsafeMutableRawPointer?#>, <#T##pixelBufferAttributes: CFDictionary?##CFDictionary?#>, <#T##pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>##UnsafeMutablePointer<CVPixelBuffer?>#>)
        
    }
    
}
