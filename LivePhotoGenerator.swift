import Photos
import MobileCoreServices

class LivePhotoGenerator {
    
    let inputImagePath: String
    let inputVideoPath: String
    let outputImagePath: String
    let outputVideoPath: String
    private let assetID: String = UUID().uuidString
    private let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    typealias Resources = (pairedImageURL: URL, pairedVideoURL: URL)
    
    
    init(inputImagePath: String, inputVideoPath: String, outputFileName: String?) {
        self.inputImagePath = inputImagePath
        self.inputVideoPath = inputVideoPath
        
        let outputFileName = outputFileName ?? "temp"
        self.outputImagePath = "\(documentsDirectory)/\(outputFileName).jpeg"
        self.outputVideoPath = "\(documentsDirectory)/\(outputFileName).mov"
        
        // Make sure file doesn't exist before writing
        if FileManager.default.fileExists(atPath: self.outputImagePath) {
            let _ = try? FileManager.default.removeItem(at: URL(fileURLWithPath: self.outputImagePath))
        }
        if FileManager.default.fileExists(atPath: self.outputVideoPath) {
            let _ = try? FileManager.default.removeItem(at: URL(fileURLWithPath: self.outputVideoPath))
        }
    }
    
    // Creates and returns a PHLivePhoto from the formatted image and video along with the Resources which include the paired image url and paired video url
    func create(completion: @escaping (PHLivePhoto?, Resources?) -> ()) {
        guard convertImageToLivePhotoFormat(inputImagePath: inputImagePath, outputImagePath: outputImagePath) else { completion(nil, nil); return }
        
        convertVideoToLivePhotoFormat(inputVideoPath: inputVideoPath, outputVideoPath: outputVideoPath, completion: { (success: Bool) in
            guard success else { completion(nil, nil); return }
            
            self.makeLivePhotoFromFormattedItems(imagePath: self.outputImagePath, videoPath: self.outputVideoPath, previewImage: UIImage(), completion: { (livePhoto: PHLivePhoto?) in
                if let livePhoto = livePhoto {
                    let resources = Resources(pairedImageURL: URL(fileURLWithPath: self.outputImagePath), pairedVideoURL: URL(fileURLWithPath: self.outputVideoPath))
                    completion(livePhoto, resources)
                } else {
                    completion(nil, nil)
                }
            })
        })
    }
    
    // Saves the Live Photo (paired image and video) from Resources to the Photo Library
    public static func writeToPhotoLibrary(resources: Resources, completion: @escaping (Bool) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            
            let request = PHAssetCreationRequest.forAsset()
            
            request.addResource(with: .photo, fileURL: resources.pairedImageURL, options: nil)
            request.addResource(with: .pairedVideo, fileURL: resources.pairedVideoURL, options: nil)
            
        }) { (success: Bool, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            }
            completion(success)
        }
    }
    
    // Links the formatted image and video
    private func makeLivePhotoFromFormattedItems(imagePath: String, videoPath: String, previewImage: UIImage, completion: @escaping (PHLivePhoto?) -> Void) {
        let imageURL = URL(fileURLWithPath: imagePath)
        let videoURL = URL(fileURLWithPath: videoPath)
        
        PHLivePhoto.request(withResourceFileURLs: [imageURL, videoURL], placeholderImage: previewImage, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto: PHLivePhoto?, infoDict: [AnyHashable : Any]) in
            completion(livePhoto)
        }
    }
    
    // Converts the image into a Live Photo format
    private func convertImageToLivePhotoFormat(inputImagePath: String, outputImagePath: String) -> Bool {
        
        guard let image = UIImage(contentsOfFile: inputImagePath) else { return false }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return false }
        
        let destinationURL = URL(fileURLWithPath: outputImagePath) as CFURL
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL, kUTTypeJPEG, 1, nil) else { return false }
        
        defer { CGImageDestinationFinalize(imageDestination) }
        
        guard let imageSource: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return false }
        
        guard let imageSourceCopyProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary? else { return false }
        guard let metadata = imageSourceCopyProperties.mutableCopy() as? NSMutableDictionary else { return false }
        
        let makerNote = NSMutableDictionary()
        let kFigAppleMakerNote_AssetIdentifier = "17"
        makerNote.setObject(assetID, forKey: kFigAppleMakerNote_AssetIdentifier as NSCopying)
        
        metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as String as String as NSCopying)
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metadata)
        
        return true
    }
    
    // Converts the video into a Live Photo format
    private func convertVideoToLivePhotoFormat(inputVideoPath: String, outputVideoPath: String, completion: @escaping (Bool) -> ()) {
        
        // Create asset writer and set its metadata
        guard let writer = try? AVAssetWriter(outputURL: URL(fileURLWithPath: outputVideoPath), fileType: .mov) else { completion(false); return }
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.content.identifier" as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = assetID as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        writer.metadata = [item]
        
        // Reader for source video
        let asset = AVURLAsset(url: URL(fileURLWithPath: inputVideoPath))
        guard let track = asset.tracks.first else { completion(false); return }
        
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)])
        guard let reader = try? AVAssetReader(asset: asset) else { completion(false); return }
        reader.add(output)
        
        // Input from video file
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: track.naturalSize.width as AnyObject,
            AVVideoHeightKey: track.naturalSize.height as AnyObject
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        writerInput.expectsMediaDataInRealTime = true
        writerInput.transform = track.preferredTransform
        writer.add(writerInput)
        
        // Create metadata adapter
        let keySpaceQuickTimeMetadata = "mdta"
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        
        let metadataSpecifications = [kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString: "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString: "com.apple.metadata.datatype.int8"]
        
        
        var formatDescription: CMFormatDescription?
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [metadataSpecifications] as CFArray, formatDescriptionOut: &formatDescription)
        let assetWriterInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: formatDescription)
        
        let adapter = AVAssetWriterInputMetadataAdaptor(assetWriterInput: assetWriterInput)
        writer.add(adapter.assetWriterInput)
        
        
        // Create video
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        // write metadata track
        let item2 = AVMutableMetadataItem()
        item2.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item2.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item2.value = 0 as (NSCopying & NSObjectProtocol)?
        item2.dataType = "com.apple.metadata.datatype.int8"
        adapter.append(AVTimedMetadataGroup(items: [item2], timeRange: CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1000), duration: CMTimeMake(value: 200, timescale: 3000))))
        
        // write video track
        writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "assetVideoWriterQueue", attributes: []), using: {
            while writerInput.isReadyForMoreMediaData {
                if reader.status == .reading {
                    if let buffer = output.copyNextSampleBuffer() {
                        if !writerInput.append(buffer) {
                            print("cannot write: \((describing: writer.error?.localizedDescription))")
                            reader.cancelReading()
                        }
                    }
                } else {
                    writerInput.markAsFinished()
                    writer.finishWriting() {
                        if let e = writer.error {
                            print(e.localizedDescription)
                            completion(false)
                            return
                        }
                    }
                }
            }
        })
        
        // wait until writer finishes writing
        while writer.status == .writing {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        
        completion(true)
    }
}
