# LiveSegment
A macOS application to perform real-time human segmentation: Blurring, coloring, or placing a custom image on the background.
- - - -

### Summary: 

Taking inspiration from software such as Apple's Clips, Portrait mode, Zoom, and the like, I ventured on a project to use machine learning segmentation on real-time video. Specifically, the user is able to blur the background, place a color on the background or upload a custom image to the background.

As of release v1, the base functionality has been implemented. In later versions the goal will be possible optimization along with virtual webcam support. 

A list of technologies as well as external libraries used are listed below:

* Xcode version 12.4 
* CoreML - Machine Learning Model: DeepLabV3Int8LUT customized to output a CVPixelBuffer. Available at: https://developer.apple.com/machine-learning/models/
* Metal
* CoreML Utility Classes: https://github.com/hollance/CoreMLHelpers


### Machine Specifications:

* macOS Big Sur, version 11.2.3
* 1.7 GHz Quad-Core Intel Core i7
* 8 GB RAM
* 1536 MB VRAM


### Known Issues:
- Data races occur in the pixel buffer between the segmentation mask classes and/or the AVMetalPreviewView
- The threshold for recomputation of the segmentation is not perfect, so slight movements will cause the prior mask to remain in place. A possible future compensation will be translating the mask along with the frame.

Work in progress: To add images/gifs/possibly new releases
