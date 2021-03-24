# LiveSegment
A macOS application to perform real-time human segmentation: Blurring, coloring, or placing a custom image on the background.
- - - -

### Summary: 

Taking inspiration from software such as Apple's Clips, Portrait mode, Zoom, and the like, I ventured on a project to use machine learning segmentation on real-time video. Specifically, the user is able to blur the background, place a color on the background or upload a custom image to the background.

As of release v1, the base functionality has been implemented. In later versions the goal will be possible optimization along with virtual webcam support. 

A list of technologies as well as external libraries used are listed below:

* CoreML - Machine Learning Model: DeepLabV3Int8LUT customized to output a CVPixelBuffer. Available at: https://developer.apple.com/machine-learning/models/
* Metal
* CoreML Utility Classes: https://github.com/hollance/CoreMLHelpers

Work In Progess: TO ADD IMAGES/GIFS, source, and release
