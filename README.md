# LivePhotoGenerator.swift
## A Swift library for creating and saving Live Photos

#### Ex. Creating and Saving a Live Photo
```swift
// Create a LivePhoto object with a image path and video path
LivePhotoGenerator(imagePath: self.imagePath, videoPath: self.videoPath).create { (livePhoto: LivePhoto?, error: Error?) in

    // Unwrap object
    if let livePhoto = livePhoto {

        // Set the Live Photo in a PHLivePhotoView
        let livePhotoView = PHLivePhotoView(frame: rect)
        livePhotoView.livePhoto = livePhoto

        // Save Live Photo to Photo Library
        livePhoto.writeToPhotoLibrary(completion: { (success: Bool, error: Error?) in

          if success {
            ...
          }
        })
    }
}
```
