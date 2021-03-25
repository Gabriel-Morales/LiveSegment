//
//  ViewController.swift
//  SegmentTest
//
//  Created by Gabriel Morales on 3/9/21.
//

import Cocoa
import AVFoundation
import Vision
import CoreFoundation
import CoreML

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, NSWindowDelegate {

    @IBOutlet var mainView: NSView!
    @IBOutlet weak var previewMetalView: AVMetalPreviewView!
    
    @IBOutlet weak var segmentChoiceControl: NSSegmentedControl!
    @IBOutlet weak var segmenterColorWell: NSColorWell!
    @IBOutlet weak var segmentBlurSlider: NSSlider!
    @IBOutlet weak var segmentUploadButton: NSButton!
    
    
    
    private var currentSelectedCtrl: Int?

    
    private var captureSession = AVCaptureSession()
    private var captureDevice = AVCaptureDevice.default(for: .video)
    private var captureOutput: AVCaptureVideoDataOutput?
    private var captureInput: AVCaptureInput?
    
    private var avoutputqueue: DispatchQueue?
    private var predictionQueue: OperationQueue?
    
    private var currentImageBuffer: CVImageBuffer?
    
    private var segmentationRenderer: SegmentedRenderer?
    private var cicontext: CIContext?

    override func viewDidLoad() {
        
        super.viewDidLoad()

        previewMetalView.layer?.cornerRadius = 10
        currentSelectedCtrl = segmentChoiceControl.selectedSegment
        
        let mtlCmdQueue = MetalResourceHelper.getInstance().getCommandQueue()!
        cicontext = CIContext(mtlCommandQueue: mtlCmdQueue, options: [.cacheIntermediates:false])
        
        startCameraSession()
        setupCameraOutput()
  
        previewMetalView.isFilteringEnabled = false
        initializePredictionQueue()
    }
    
    
    fileprivate func initializePredictionQueue() {
        predictionQueue = OperationQueue()
        predictionQueue?.maxConcurrentOperationCount = 1
    }
    
    fileprivate func resetQueueForNextFilter() {
        destroyPredictionQueue()
        initializePredictionQueue()
        segmentationRenderer?.cicontext = self.cicontext
    }
    
    fileprivate func destroyPredictionQueue() {
        predictionQueue?.isSuspended = true
        predictionQueue?.cancelAllOperations()
        predictionQueue?.isSuspended = false
        predictionQueue = nil
    }
    
    fileprivate func startCameraSession() {
        
        do {
            captureInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.beginConfiguration()
        
            if captureSession.canAddInput(captureInput!) {
                captureSession.addInput(captureInput!)
            }
            
        } catch {
            print("Unable to use device for input!")
        }
        
    }
    
    fileprivate func setupCameraOutput() {
        
        captureOutput = AVCaptureVideoDataOutput()
        avoutputqueue = DispatchQueue(label: "output queue", qos: .userInitiated, autoreleaseFrequency: .workItem)
        
        if captureSession.canAddOutput(captureOutput!) {
            
            captureSession.addOutput(captureOutput!)
            captureOutput!.alwaysDiscardsLateVideoFrames = true
            captureOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            captureOutput!.setSampleBufferDelegate(self, queue: avoutputqueue)
            
        } else {
            print("Unable to use device for output!")
            captureSession.commitConfiguration()
        }

        captureSession.commitConfiguration()
        DispatchQueue.init(label: "camera queue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem).async {
            self.captureSession.startRunning()
        }
        
    }

   
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        currentImageBuffer = imageBuffer

        guard let segmentRenderer = segmentationRenderer else {
            self.previewMetalView.pixelBuffer = self.currentImageBuffer
            return
        }

        var alteredPixelBuffer: CVPixelBuffer?
        if previewMetalView.isFilteringEnabled {
 
            segmentRenderer.pixelBuffer = imageBuffer
            
            predictionQueue?.addOperation {
                alteredPixelBuffer = segmentRenderer.applyFilter()
                self.previewMetalView.pixelBuffer = alteredPixelBuffer
            }

            
        } else {
            previewMetalView.pixelBuffer = currentImageBuffer
        }

    }
    
    
    fileprivate func switchToFilteringMode() {
        previewMetalView.isFilteringEnabled = true
        resetQueueForNextFilter()
    }
    
    @IBAction func selectSegmentChoiceAction(_ sender: Any) {
        
        let choice = segmentChoiceControl.selectedSegment
        
        switch choice {
            case currentSelectedCtrl:
                return
            case 0: // no masking choice
                previewMetalView.isFilteringEnabled = false
                segmenterColorWell.isHidden = true
                segmentBlurSlider.isHidden = true
                segmentUploadButton.isHidden = true
                destroyPredictionQueue()
            case 1: // color masking choice
                segmenterColorWell.isHidden = false
                segmentUploadButton.isHidden = true
                segmentBlurSlider.isHidden = true
                segmentationRenderer = ColorMaskSegmenter()
                switchToFilteringMode()
            case 2: // blur masking choice
                segmenterColorWell.isHidden = true
                segmentUploadButton.isHidden = true
                segmentBlurSlider.isHidden = false
                segmentationRenderer = BlurMaskSegmenter()
                switchToFilteringMode()
            case 3: // image masking choice
                segmenterColorWell.isHidden = true
                segmentBlurSlider.isHidden = true
                segmentUploadButton.isHidden = false
                segmentationRenderer = ImageMaskSegmenter()
                switchToFilteringMode()
            default:
                break
        }
        
        currentSelectedCtrl = choice
        
    }
    
    
    
    @IBAction func colorWellChoiceAction(_ sender: Any) {
    
        let colorChoice = segmenterColorWell.color
        
        DispatchQueue.global().async {
            (self.segmentationRenderer as! ColorMaskSegmenter).colorChoice = colorChoice
        }
        
    }
    
    
    @IBAction func sliderBlurAction(_ sender: Any) {
        
        let blurLevel = segmentBlurSlider.floatValue
        
        DispatchQueue.global().async {
            (self.segmentationRenderer as! BlurMaskSegmenter).radiusLevel = blurLevel
        }
    }
    
    @IBAction func uploadImageAction(_ sender: Any) {
        
        let documentController = NSDocumentController()
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        
        documentController.runModalOpenPanel(openPanel, forTypes: ["jpeg", "jpg", "png", "gif"])
        
        let imageUrl = openPanel.url
        let image = CIImage(contentsOf: imageUrl!)
        
        (segmentationRenderer as! ImageMaskSegmenter).selectedImg = image
    }
    
    
    override func viewWillAppear() {
        mainView.window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        // release all camera resources.
        
        captureSession.removeInput(captureInput!)
        captureSession.removeOutput(captureOutput!)
        captureOutput = nil
        captureDevice = nil
        captureInput = nil
        avoutputqueue = nil
        currentImageBuffer = nil
        
        NSApp.stop(NSApp)
    }
    
}

