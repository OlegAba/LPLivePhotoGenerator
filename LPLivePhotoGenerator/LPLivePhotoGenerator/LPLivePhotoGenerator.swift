import Photos
import MobileCoreServices

public class LPLivePhotoGenerator {
    
    public enum LPError: Error {
        case imageConversionFailed(String)
        case videoConversionFailed(String)
        case livePhotoCreationFailed(String)
    }
    
    // Create and returns a LivePhoto object from the formatted image and video which include the paired image URL and paired video URL
    public static func create(inputImagePath: String, inputVideoPath: String, completion: @escaping (LPLivePhoto?, LPError?) -> ()) {
        
        let assetID: String = UUID().uuidString
        
        let outputImageURL = createTempDirectoryPathWith(fileName: assetID + ".jpeg")
        let outputVideoURL = createTempDirectoryPathWith(fileName: assetID + ".mov")
        
        if let error = convertImageToLivePhotoFormat(inputImagePath: inputImagePath, outputImageURL: outputImageURL, assetID: assetID) {
            completion(nil, error)
            return
        }
        
        convertVideoToLivePhotoFormat(inputVideoPath: inputVideoPath, outputVideoURL: outputVideoURL, assetID: assetID) { (success: Bool, error: LPError?) in
            guard success else { completion(nil, error); return }
            
            makeLivePhotoFromFormattedItems(imageURL: outputImageURL, videoURL: outputVideoURL, previewImage: UIImage(), completion: { (livePhoto: PHLivePhoto?) in
                
                if let livePhoto = livePhoto {
                    completion(LPLivePhoto(phLivePhoto: livePhoto, imageURL: outputImageURL, videoURL: outputVideoURL, assetID: assetID), nil)
                    return
                } else {
                    completion(nil, LPError.livePhotoCreationFailed("Metadata of image and/or video is invalid"))
                    return
                }
            })
            
        }
    }
    
    // Links the formatted image and video
    public static func makeLivePhotoFromFormattedItems(imageURL: URL, videoURL: URL, previewImage: UIImage, completion: @escaping (PHLivePhoto?) -> ()) {
        
        PHLivePhoto.request(withResourceFileURLs: [imageURL, videoURL], placeholderImage: previewImage, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto: PHLivePhoto?, infoDict: [AnyHashable : Any]) in
            
            // Wait until all live photo data is loaded
            guard let _ = infoDict[PHLivePhotoInfoIsDegradedKey] as? Bool else { completion (livePhoto); return }
        }
    }
    
    // Creates temporary directory URL with an appending file name
    private static func createTempDirectoryPathWith(fileName: String) -> URL {
        
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
        return tempDirectoryURL
    }
    
    // Converts the image into a Live Photo format
    private static func convertImageToLivePhotoFormat(inputImagePath: String, outputImageURL: URL, assetID: String) -> (LPError?) {
        
        guard let image = UIImage(contentsOfFile: inputImagePath) else { return LPError.imageConversionFailed("Invalid image") }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return LPError.imageConversionFailed("Invalid JPEG image") }
        
        let destinationURL = outputImageURL as CFURL
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL, kUTTypeJPEG, 1, nil) else { return LPError.imageConversionFailed("The specified directory does not exist") }
        
        defer { CGImageDestinationFinalize(imageDestination) }
        
        guard let imageSource: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return LPError.imageConversionFailed("Image data is missing") }
        
        guard let imageSourceCopyProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary? else { return LPError.imageConversionFailed("Metadata of image is missing") }
        
        guard let metadata = imageSourceCopyProperties.mutableCopy() as? NSMutableDictionary else { return LPError.imageConversionFailed("Metadata of image could not be copied") }
        
        let makerNote = NSMutableDictionary()
        let kFigAppleMakerNote_AssetIdentifier = "17"
        makerNote.setObject(assetID, forKey: kFigAppleMakerNote_AssetIdentifier as NSCopying)
        
        metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as String as String as NSCopying)
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metadata)
        
        return nil
    }
    
    // Converts the video into a Live Photo format
    private static func convertVideoToLivePhotoFormat(inputVideoPath: String, outputVideoURL: URL, assetID: String, completion: @escaping (Bool, LPError?) -> ()) {
        
        // Create asset writer and set its metadata
        guard let writer = try? AVAssetWriter(outputURL: outputVideoURL, fileType: .mov) else { completion(false, LPError.videoConversionFailed("The specified directory does not exist")); return }
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.content.identifier" as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = assetID as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        writer.metadata = [item]
        
        // Reader for source video
        let asset = AVURLAsset(url: URL(fileURLWithPath: inputVideoPath))
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { completion(false, LPError.videoConversionFailed("Video track is in unavailable format")); return }
        
        let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)])
        guard let videoReader = try? AVAssetReader(asset: asset) else { completion(false, LPError.videoConversionFailed("Video data is in an unsupported format")); return }
        videoReader.add(output)
        
        // Input from video file
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: videoTrack.naturalSize.width as AnyObject,
            AVVideoHeightKey: videoTrack.naturalSize.height as AnyObject
        ]
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = videoTrack.preferredTransform
        writer.add(videoWriterInput)
        
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
        
        
        // Create audio reader and writer
        var audioReader: AVAssetReader?
        var audioReaderOutput: AVAssetReaderOutput?
        var audioWriterInput: AVAssetWriterInput?
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            guard let audioReaderTemp = try? AVAssetReader(asset: asset) else {completion(false, LPError.videoConversionFailed("Audio data is in an unsupported format")); return}
            let audioOutputTemp = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            audioReaderTemp.add(audioOutputTemp)
            audioReader = audioReaderTemp
            audioReaderOutput = audioOutputTemp
            
            let audioInputTemp = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            audioInputTemp.expectsMediaDataInRealTime = false
            writer.add(audioInputTemp)
            audioWriterInput = audioInputTemp
        }
        
        
        // Create video
        writer.startWriting()
        videoReader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        // Write metadata track
        let item2 = AVMutableMetadataItem()
        item2.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item2.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item2.value = 0 as (NSCopying & NSObjectProtocol)?
        item2.dataType = "com.apple.metadata.datatype.int8"
        adapter.append(AVTimedMetadataGroup(items: [item2], timeRange: CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1000), duration: CMTimeMake(value: 200, timescale: 3000))))
        
        
        // Write video track
        videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "assetVideoWriterQueue", attributes: []), using: {
            while videoWriterInput.isReadyForMoreMediaData {
                if videoReader.status == .reading {
                    if let buffer = output.copyNextSampleBuffer() {
                        if !videoWriterInput.append(buffer) {
                            videoReader.cancelReading()
                            let localizedDescription = writer.error?.localizedDescription ?? ""
                            completion(false, LPError.videoConversionFailed("Cannot write: \(localizedDescription)"))
                        }
                    }
                } else {
                    videoWriterInput.markAsFinished()
                    writer.finishWriting() {
                        if let e = writer.error {
                            completion(false, LPError.videoConversionFailed(e.localizedDescription))
                            return
                        }
                    }
                }
            }
        })
        
        
        // Write audio track
        if audioReader?.startReading() ?? false {
            audioWriterInput?.requestMediaDataWhenReady(on: DispatchQueue(label: "assetAudioWriterQueue")) {
                while audioWriterInput?.isReadyForMoreMediaData ?? false {
                    if let buffer = audioReaderOutput?.copyNextSampleBuffer() {
                        audioWriterInput?.append(buffer)
                    } else {
                        audioWriterInput?.markAsFinished()
                        return
                    }
                }
            }
        }
        
        
        
        // Wait until writer finishes writing
        while writer.status == .writing {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        
        completion(true, nil)
    }
    
}
