import Photos

class LivePhoto {
    
    let phLivePhoto: PHLivePhoto
    let imageURL: URL
    let videoURL: URL
    let assetID: String
    
    enum LivePhotoError: Error {
        case imageMoveFailed(String)
        case videoMoveFailed(String)
        case imageRemoveFailed(String)
        case videoRemoveFailed(String)
    }
    
    init(phLivePhoto: PHLivePhoto, imageURL: URL, videoURL: URL, assetID: String) {
        self.phLivePhoto = phLivePhoto
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.assetID = assetID
    }
    
    // Saves Live Photo (paired image and video) to the Photo Library
    func writeToPhotoLibrary(completion: @escaping (Bool, Error?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            
            let request = PHAssetCreationRequest.forAsset()
            
            request.addResource(with: .photo, fileURL: self.imageURL, options: nil)
            request.addResource(with: .pairedVideo, fileURL: self.videoURL, options: nil)
            
        }) { (success: Bool, error: Error?) in
            if let error = error {
                completion(success, error)
            }
            completion(success, LivePhotoError.videoRemoveFailed("At path"))
        }
    }
    
    // Move paired image and video to new path
    func movePairedFilesTo(path: String, completion: @escaping (Bool, Error?) -> ()) {
        let newImageURL = URL(fileURLWithPath: path + "/\(self.assetID).jpeg")
        let newVideoURL = URL(fileURLWithPath: path + "/\(self.assetID).mov")
        
        if (try? FileManager.default.moveItem(at: imageURL, to: newImageURL)) != nil {
            print("Image file moved to \(newImageURL.path)")
        } else {
            completion(false, LivePhotoError.imageMoveFailed("To path \(newImageURL.path)"))
            return
        }
        
        if (try? FileManager.default.moveItem(at: videoURL, to: newVideoURL)) != nil {
            print("Image file moved to \(newVideoURL.path)")
        } else {
            completion(false, LivePhotoError.videoMoveFailed("To path \(newVideoURL.path)"))
            return
        }
        
        completion(true, nil)
    }
    
    // Removes paired image and video in temporary directory
    func removeFilesFromTempDirectory(completion: @escaping (Bool, Error?) -> ()) {
        if (try? FileManager.default.removeItem(at: imageURL)) != nil {
            print("Image file removed at path \(imageURL.path)")
        } else {
            completion(false, LivePhotoError.imageRemoveFailed("At path \(imageURL.path)"))
            return
        }

        if (try? FileManager.default.removeItem(at: videoURL)) != nil {
            print("Video file removed at path \(videoURL.path)")
        } else {
            completion(false, LivePhotoError.videoRemoveFailed("At path \(videoURL.path)"))
            return
        }

        completion(true, nil)
    }

}
