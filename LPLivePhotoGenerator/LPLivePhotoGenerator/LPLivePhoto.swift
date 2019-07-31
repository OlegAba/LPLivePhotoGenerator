import Photos

public class LPLivePhoto {
    
    public let phLivePhoto: PHLivePhoto
    public let imageURL: URL
    public let videoURL: URL
    public let assetID: String
    
    public enum LPError: Error {
        case writeToPhotoLibraryFailed(String)
        case imageMoveFailed(String)
        case videoMoveFailed(String)
        case imageRemoveFailed(String)
        case videoRemoveFailed(String)
    }
    
    public init(phLivePhoto: PHLivePhoto, imageURL: URL, videoURL: URL, assetID: String) {
        self.phLivePhoto = phLivePhoto
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.assetID = assetID
    }
    
    // Saves Live Photo (paired image and video) to the Photo Library
    public func writeToPhotoLibrary(completion: @escaping (LPLivePhoto, LPError?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            
            let request = PHAssetCreationRequest.forAsset()
            
            request.addResource(with: .photo, fileURL: self.imageURL, options: nil)
            request.addResource(with: .pairedVideo, fileURL: self.videoURL, options: nil)
            
        }) { (success: Bool, error: Error?) in
            if let error = error {
                completion(self, LPError.writeToPhotoLibraryFailed(error.localizedDescription))
            }
            completion(self, nil)
        }
    }
    
    // Move paired image and video to new path
    public func movePairedImageAndVideoTo(path: String, completion: @escaping (Bool, LPError?) -> ()) {
        let newImageURL = URL(fileURLWithPath: path + "/\(self.assetID).jpeg")
        let newVideoURL = URL(fileURLWithPath: path + "/\(self.assetID).mov")
        
        if (try? FileManager.default.moveItem(at: imageURL, to: newImageURL)) != nil {
            print("Image file moved to \(newImageURL.path)")
        } else {
            completion(false, LPError.imageMoveFailed("The specified directory does not exist: \(newImageURL.path)"))
            return
        }
        
        if (try? FileManager.default.moveItem(at: videoURL, to: newVideoURL)) != nil {
            print("Image file moved to \(newVideoURL.path)")
        } else {
            completion(false, LPError.videoMoveFailed("The specified directory does not exist: \(newVideoURL.path)"))
            return
        }
        
        completion(true, nil)
    }
    
    // Removes paired image and video in temporary directory
    public func removeFilesFromTempDirectory(completion: @escaping (Bool, LPError?) -> ()) {
        if (try? FileManager.default.removeItem(at: imageURL)) != nil {
            print("Image file removed at path \(imageURL.path)")
        } else {
            completion(false, LPError.imageRemoveFailed("No file exists at path: \(imageURL.path)"))
            return
        }
        
        if (try? FileManager.default.removeItem(at: videoURL)) != nil {
            print("Video file removed at path \(videoURL.path)")
        } else {
            completion(false, LPError.videoRemoveFailed("No file exists at path: \(videoURL.path)"))
            return
        }
        
        completion(true, nil)
    }
    
}
