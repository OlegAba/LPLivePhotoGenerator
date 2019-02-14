# LivePhotoGenerator.swift
## A Swift library for creating and saving Live Photos

#### Ex. Creating and Saving a Live Photo
```swift
// outputFileName defaults to temp if one is not provided
let livePhotoGenerator = LivePhotoGenerator(inputImagePath: inputVideoPath, inputVideoPath: videoFilePath, outputFileName: nil)

livePhotoGenerator.create(completion: ({ livePhoto: PHLivePhoto?, resources: LivePhotoGenerator.Resources?) in

  // Unwrap values
  guard let livePhoto = livePhoto else { completion(nil, nil); return }
  guard let resources = resources else { completion(nil, nil); return }
  
  // Set the Live Photo in a PHLivePhotoView
  let livePhotoView = PHLivePhotoView(frame: rect)
  livePhotoView.livePhoto = livePhoto
  
  // Save Live Photo to Photo Library
  livePhotoGenerator.writeToPhotoLibrary(resources: resources) { (success: Bool) in
    if success {
      ...
}))
```
