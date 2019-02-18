# LivePhotoGenerator.swift
## A Swift library for creating and saving Live Photos

#### Creating and Saving a Live Photo:
```swift
// Create a LivePhoto object with a image path and video path
LivePhotoGenerator(imagePath: imagePath, videoPath: videoPath).create { (livePhoto: LivePhoto?, error: Error?) in

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

#### Extra Tools (LivePhoto Object Methods):
```swift
// Move paired image and video to new path
livePhoto.movePairedFilesTo(path: path, completion: { (success: Bool, error: Error?) in

    if success {
        ...
    }
})

// Remove paired image and video from temporary directory
livePhoto.removeFilesFromDirectory(completion: { (success: Bool, error: Error?) in
    
    if success {
        ...
    }
)}
```
