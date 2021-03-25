//
//  CustomNSWindowController.swift
//  SegmentTest
//
//  Created by Gabriel Morales on 3/10/21.
//

import Foundation
import CoreFoundation
import Cocoa

class CustomNSWindow: NSWindow {
    
    override init(contentRect cr: NSRect, styleMask sm: NSWindow.StyleMask, backing bk: NSWindow.BackingStoreType, defer def: Bool){
        
        let rect = NSRect(x: 0, y: 0, width: NSScreen.screens[0].frame.width, height: NSScreen.screens[0].frame.height)
        
        super.init(contentRect: rect, styleMask: sm, backing: bk, defer: def)
        
        
    }
    
}
