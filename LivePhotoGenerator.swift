
import Photos
import MobileCoreServices

class LivePhotoGenerator {
    
    enum LivePhotoGeneratorError: Error {
        case imageConversionFailed(String)
        case videoConversionFailed(String)
        case livePhotoCreationFailed(String)
    }
    
    // Create and returns a LivePhoto object from the formatted image and video which include the paired image URL and paired video URL
    static func create(inputImagePath: String, inputVideoPath: String, completion: @escaping (LivePhoto?, LivePhotoGeneratorError?) -> ()) {
        
        let assetID: String = UUID().uuidString
        
        let outputImageURL = createTempDirectoryPathWith(fileName: assetID + ".jpeg")
        let outputVideoURL = createTempDirectoryPathWith(fileName: assetID + ".mov")
        
        let (success, error) = convertImageToLivePhotoFormat(inputImagePath: inputImagePath, outputImageURL: outputImageURL, assetID: assetID)
        // TODO: Possible to write into one statement ???
        if !success { completion(nil, error); return }
        
        convertVideoToLivePhotoFormat(inputVideoPath: inputVideoPath, outputVideoURL: outputVideoURL, assetID: assetID) { (success: Bool, error: LivePhotoGeneratorError?) in
            guard success else { completion(nil, error); return }
            
            makeLivePhotoFromFormattedItems(imageURL: outputImageURL, videoURL: outputVideoURL, previewImage: UIImage(), completion: { (livePhoto: PHLivePhoto?) in
                
                if let livePhoto = livePhoto {
                    completion(LivePhoto(phLivePhoto: livePhoto, imageURL: outputImageURL, videoURL: outputVideoURL, assetID: assetID), nil)
                    return
                } else {
                    // TODO: Internal Error
                    completion(nil, LivePhotoGeneratorError.livePhotoCreationFailed("Metadata of image and/or video is invalid"))
                    return
                }
            })
            
        }
    }
    
    // Creates temporary directory URL with an appending file name
    private static func createTempDirectoryPathWith(fileName: String) -> URL {
        
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
        return tempDirectoryURL
    }
    
    // Links the formatted image and video
    private static func makeLivePhotoFromFormattedItems(imageURL: URL, videoURL: URL, previewImage: UIImage, completion: @escaping (PHLivePhoto?) -> ()) {
        
        PHLivePhoto.request(withResourceFileURLs: [imageURL, videoURL], placeholderImage: previewImage, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto: PHLivePhoto?, infoDict: [AnyHashable : Any]) in
            
            guard let _ = infoDict[PHLivePhotoInfoIsDegradedKey] as? Bool else { completion (livePhoto); return }
        }
    }
    
    // Converts the image into a Live Photo format
    private static func convertImageToLivePhotoFormat(inputImagePath: String, outputImageURL: URL, assetID: String) -> (Bool, LivePhotoGeneratorError?) {
        
        guard let image = UIImage(contentsOfFile: inputImagePath) else { return (false, LivePhotoGeneratorError.imageConversionFailed("Invalid image")) }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return (false, LivePhotoGeneratorError.imageConversionFailed("Invalid JPEG image")) }
        
        let destinationURL = outputImageURL as CFURL
        // TODO: Return internal errors ???
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL, kUTTypeJPEG, 1, nil) else { return (false, LivePhotoGeneratorError.imageConversionFailed("The specified directory does not exist")) }
        
        defer { CGImageDestinationFinalize(imageDestination) }
        
        guard let imageSource: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return (false, LivePhotoGeneratorError.imageConversionFailed("Image data is missing")) }
        
        guard let imageSourceCopyProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary? else { return (false, LivePhotoGeneratorError.imageConversionFailed("Metadata of image is missing")) }
        // TODO: Internal Error
        guard let metadata = imageSourceCopyProperties.mutableCopy() as? NSMutableDictionary else { return (false, LivePhotoGeneratorError.imageConversionFailed("Metadata of image could not be copied")) }
        
        let makerNote = NSMutableDictionary()
        let kFigAppleMakerNote_AssetIdentifier = "17"
        makerNote.setObject(assetID, forKey: kFigAppleMakerNote_AssetIdentifier as NSCopying)
        
        metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as String as String as NSCopying)
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metadata)
        
        return (true, nil)
    }
    
    // Converts the video into a Live Photo format
    private static func convertVideoToLivePhotoFormat(inputVideoPath: String, outputVideoURL: URL, assetID: String, completion: @escaping (Bool, LivePhotoGeneratorError?) -> ()) {
        
        // Create asset writer and set its metadata
        // TODO: Internal Error
        guard let writer = try? AVAssetWriter(outputURL: outputVideoURL, fileType: .mov) else { completion(false, LivePhotoGeneratorError.videoConversionFailed("The specified directory does not exist")); return }
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.content.identifier" as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = assetID as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        writer.metadata = [item]
        
        // Reader for source video
        let asset = AVURLAsset(url: URL(fileURLWithPath: inputVideoPath))
        // TODO: Internal Error
        guard let track = asset.tracks.first else { completion(false, LivePhotoGeneratorError.videoConversionFailed("Video track is in an unsupported format")); return }
        
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)])
        // TODO: Internal Error
        guard let reader = try? AVAssetReader(asset: asset) else { completion(false, LivePhotoGeneratorError.videoConversionFailed("Video data is in an unsupported format")); return }
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
                            // TODO: Return false and error here ???
                            print("cannot write: \((describing: writer.error?.localizedDescription))")
                            reader.cancelReading()
                        }
                    }
                } else {
                    writerInput.markAsFinished()
                    writer.finishWriting() {
                        if let e = writer.error {
                            completion(false, LivePhotoGeneratorError.videoConversionFailed(e.localizedDescription))
                            return
                        }
                    }
                }
            }
        })
        
        
        
        //TODO: NOT WRITING AUDIO TRACK
        
        // TODO: Look for an alternative to statement below
        // wait until writer finishes writing
        while writer.status == .writing {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        
        completion(true, nil)
    }
    
}
