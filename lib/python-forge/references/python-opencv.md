# Python OpenCV

Index of OpenCV (cv2) usage in Python: installation, critical gotchas such as BGR ordering and coordinate conventions, and pointers to detailed references.

## Quick Reference

| Function | Purpose | Gotcha |
|----------|---------|--------|
| `cv2.imread(path)` | Load image | Returns `None` if path invalid (no error!) |
| `cv2.imwrite(path, img)` | Save image | Expects BGR, not RGB |
| `cv2.cvtColor(img, code)` | Color conversion | BGR is default, not RGB |
| `cv2.VideoCapture(src)` | Video/camera input | Always check `isOpened()` and `release()` |
| `cv2.VideoWriter(...)` | Save video | Expects BGR frames, codec matters |
| `cv2.resize(img, (w, h))` | Resize image | Size is (width, height), not (height, width) |

| Coordinate System | Order | Usage |
|-------------------|-------|-------|
| NumPy indexing | `img[row, col]` = `img[y, x]` | Pixel access |
| Image shape | `(height, width, channels)` | Shape is (rows, cols, ch) |
| OpenCV functions | `(x, y)` | Drawing functions |
| Resize/ROI | `(width, height)` | Size parameters |

| Color Conversion | Code | Note |
|------------------|------|------|
| BGR to RGB | `cv2.COLOR_BGR2RGB` | For Matplotlib display |
| BGR to Gray | `cv2.COLOR_BGR2GRAY` | Single channel output |
| BGR to HSV | `cv2.COLOR_BGR2HSV` | H: 0-179, S/V: 0-255 |

| Interpolation | Best For | Speed |
|---------------|----------|-------|
| `INTER_NEAREST` | Speed, pixelated OK | Fastest |
| `INTER_LINEAR` | General purpose (default) | Fast |
| `INTER_AREA` | Downscaling | Medium |
| `INTER_CUBIC` | Upscaling quality | Slow |
| `INTER_LANCZOS4` | Best upscaling | Slowest |

## Overview

OpenCV (Open Source Computer Vision Library) is the most popular computer vision library. Python bindings (`opencv-python`) provide access to all functionality through NumPy arrays. OpenCV uses **BGR** color format by default, which is a critical gotcha.

## Installation

```bash
# CPU-only (most common)
pip install opencv-python

# With contrib modules (extra trackers, cv2.legacy, ximgproc, etc.)
# SIFT is in the main package since 4.4. SURF is patented ("non-free") and is
# NOT in any pip wheel; it needs a custom build with OPENCV_ENABLE_NONFREE=ON
pip install opencv-contrib-python

# Headless (no GUI, for servers)
pip install opencv-python-headless

# Verify installation
python -c "import cv2; print(cv2.__version__)"
```

## Key Gotchas

- OpenCV uses BGR, not RGB; convert before Matplotlib/PIL display and convert back before `cv2.imwrite`.
- Image shape is `(height, width, channels)`, NumPy indexing is `img[row, col]`, but OpenCV drawing functions use `(x, y)`.
- `cv2.imread` returns `None` on missing or undecodable files; always check before using the image.
- `VideoCapture` and GUI windows must be released/closed in `finally` or context-manager cleanup paths.
- NumPy arithmetic can overflow on `uint8`; use OpenCV saturating arithmetic with full-shape operands (a bare scalar only affects the first channel) or explicit float normalization.

Read [opencv-critical-gotchas.md](opencv-critical-gotchas.md) for complete examples and safe patterns.

## Reference Map

This file is an index; for any code task, load the matching deep-dive reference. Detailed API patterns and code recipes live in the following files.

### Critical Gotchas -> [opencv-critical-gotchas.md](opencv-critical-gotchas.md)

Read this for full examples of the most common OpenCV failure modes:

- **BGR/RGB conversion**: Matplotlib and PIL integration, correct `cv2.imwrite` usage
- **Coordinate ordering**: shape, NumPy indexing, drawing functions, ROI slicing
- **Failed image loads**: `cv2.imread` `None` checks and pathlib validation
- **Video cleanup**: `VideoCapture` release patterns and context-manager wrapper
- **Dtype safety**: `uint8` overflow, `cv2.add`, float normalization, Canny dtype expectations

### Core Operations -> [opencv-core-operations.md](opencv-core-operations.md)

Read this for everyday OpenCV work:

- **Image I/O**: `cv2.imread` flags, loading from URLs, `cv2.imwrite` quality params, multi-image batch loading
- **Video Capture and Writing**: camera/file capture, `VideoWriter` codecs (mp4v, XVID, H264), FPS/resolution probing
- **Color Space Conversions**: BGR/RGB/HSV/Gray/Lab, HSV color detection (red/green/blue ranges with dual-range red), white-balance helpers
- **Image Filtering**: GaussianBlur, medianBlur, bilateralFilter, Sobel/Laplacian/Canny edge detection, morphological ops (erode, dilate, open, close, gradient, tophat)
- **Contour Detection**: `findContours`, area/perimeter, bounding boxes, contour approximation, hierarchy
- **Image Resizing and Transformations**: aspect-ratio-preserving resize, rotation, affine/perspective transforms, warpAffine vs warpPerspective
- **Template Matching**: `cv2.matchTemplate`, multi-scale matching, `TM_CCOEFF_NORMED` thresholding
- **Feature Detection**: ORB, SIFT, AKAZE keypoints; BFMatcher and FLANN matchers; ratio test
- **DNN Module**: `cv2.dnn.readNet` for ONNX/TF/Caffe, blob preprocessing, YOLO/MobileNet inference
- **Displaying Images**: `cv2.imshow` + `waitKey` loops, Jupyter `cv2.imshow` workaround with Matplotlib
- **Performance Tips**: vectorized NumPy, contiguous arrays, `cv2.UMat` for OpenCL, `cv2.cuda` GPU operations
- **Drawing Functions**: rectangle, circle, line, ellipse, polylines, fillPoly, putText, getTextSize

### Advanced Patterns -> [opencv-advanced-patterns.md](opencv-advanced-patterns.md)

Read this for specialized computer-vision pipelines:

- **Background Subtraction**: MOG2, KNN
- **Object Tracking**: MIL; CSRT, KCF, MOSSE, and legacy multi-object trackers (opencv-contrib-python)
- **Camera Calibration**: chessboard corner detection, intrinsic/distortion matrices, `undistort`
- **Stereo Vision**: StereoBM, StereoSGBM, disparity maps
- **Optical Flow**: Lucas-Kanade sparse, Farneback dense
- **Image Stitching**: `cv2.Stitcher` panorama assembly
- **Face Detection**: Haar cascades, DNN face detector
- **ArUco Markers**: marker detection and pose estimation

## Related References

- [`python-asyncio.md`](python-asyncio.md) - Async processing
- [`python-type-hints.md`](python-type-hints.md) - Type hints
