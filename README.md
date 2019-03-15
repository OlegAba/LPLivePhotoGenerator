# LPLivePhotoGenerator

[![GitHub release](https://img.shields.io/github/release/OlegAba/LPLivePhotoGenerator.svg)](https://github.com/OlegAba/LPLivePhotoGenerator/releases)
[![GitHub license](https://img.shields.io/github/license/OlegAba/LPLivePhotoGenerator.svg)](https://github.com/OlegAba/LPLivePhotoGenerator/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/LPLivePhotoGenerator.svg)](https://cocoapods.org/pods/LPLivePhotoGenerator)

A Swift library for creating and saving Live Photos

## Installation

#### As a [CocoaPods](https://cocoapods.org) Dependency:
Add the following to your Podfile:
```
pod 'LPLivePhotoGenerator'
```
`cd` into the directory where your Podfile is present and install
```
pod install
```

#### Manual Installation (Framework):
1. Drag the `LPLivePhotoGenerator.xcodeproj` file into your Xcode project.
2. Add `LPLivePhotoGenerator.framework` to "Embedded Binaries" in the "General" tab of your target.

## Usage

#### 1. Import LPLivePhotoGenerator
Import LPLivePhotoGenerator module wherever you want to use it:
```swift
import LPLivePhotoGenerator
```

#### 2. Creating and Saving a Live Photo:
```swift
// Create a LivePhoto object with a image path and video path
LPLivePhotoGenerator.create(inputImagePath: imagePath, inputVideoPath: videoPath) { (livePhoto: LPLivePhoto?, error: Error?) in

    // Unwrap object
    if let livePhoto = livePhoto {

        // Set the Live Photo in a PHLivePhotoView
        let livePhotoView = PHLivePhotoView(frame: rect)
        livePhotoView.livePhoto = livePhoto

        // Save Live Photo to Photo Library
        livePhoto.writeToPhotoLibrary(completion: { (livePhoto: LPLivePhoto, error: Error?) in

          if error == nil {
            ...
          }
        })
    }
}
```

#### 3. Extra Tool (LPLivePhoto Method):
```swift
// Move paired image and video to new path
livePhoto.movePairedImageAndVideoTo(path: path, completion: { (success: Bool, error: Error?) in

    if success {
        ...
    }
})
```

## Demo Application
The "Demo" is a basic reference application created to show how to install LPLivePhotoGenerator using CocoaPods and develop applications using this library.

### Installation
[CocoaPods](https://cocoapods.org) should be installed before continuing.
To access the project, run the following:
```
git clone --recursive https://github.com/OlegAba/LPLivePhotoGenerator.git
cd LPLivePhotoGenerator/Demo/
pod install
open Demo.xcworkspace
```

_You can also check out [SuperSnapcode](https://github.com/OlegAba/SuperSnapcode) - an open-source iOS application that is built using this library_

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/OlegAba/LivePhotoGenerator/blob/master/LICENSE) file for details
