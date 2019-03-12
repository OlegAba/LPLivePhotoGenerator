import UIKit
import PhotosUI
import LPLivePhotoGenerator

class MainViewController: UIViewController {
    
    var createButton: UIButton!
    var createActivityIndicatorView: UIActivityIndicatorView!
    var viewButton: UIButton!
    var saveButton: UIButton!
    
    var imagePath: String!
    var videoPath: String!
    var livePhoto: LPLivePhoto?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePath = Bundle.main.path(forResource: "image", ofType: "JPEG")
        videoPath = Bundle.main.path(forResource: "video", ofType: "MOV")
        
        view.backgroundColor = UIColor.black
        
        let height = view.frame.height / 4
        let width = view.frame.width * 0.8
        let spaceBetween = height / 4
        
        createButton = ActionButton(frame: CGRect(x: 0, y: spaceBetween, width: width, height: height), title: "Create Live Photo", hidden: false)
        createButton.center.x = view.center.x
        createButton.addTarget(self, action: #selector(createButtonWasPressed), for: .touchUpInside)
    
        viewButton = ActionButton(frame: CGRect(x: 0, y: createButton.frame.maxY + spaceBetween, width: width, height: height), title: "View Live Photo", hidden: true)
        viewButton.center.x = view.center.x
        viewButton.addTarget(self, action: #selector(viewButtonWasPressed), for: .touchUpInside)
        
        createActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        createActivityIndicatorView.center = viewButton.center
        
        saveButton = ActionButton(frame: CGRect(x: 0, y: viewButton.frame.maxY + spaceBetween, width: width, height: height), title: "Save Live Photo", hidden: true)
        saveButton.center.x = view.center.x
        saveButton.addTarget(self, action: #selector(saveButtonWasPressed), for: .touchUpInside)
        
        view.addSubview(createButton)
        view.addSubview(createActivityIndicatorView)
        view.addSubview(viewButton)
        view.addSubview(saveButton)
    }

    @objc func createButtonWasPressed() {
        
        self.viewButton.isHidden = true
        self.saveButton.isHidden = true
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.setTitle("Save Live Photo", for: .normal)
        self.saveButton.setTitleColor(UIColor.white, for: .normal)
        
        createActivityIndicatorView.startAnimating()
        
        LPLivePhotoGenerator.create(inputImagePath: self.imagePath, inputVideoPath: self.videoPath) { (livePhoto: LPLivePhoto?, error: Error?) in
            if let livePhoto = livePhoto {
                self.livePhoto = livePhoto
                self.createActivityIndicatorView.stopAnimating()
                self.viewButton.isHidden = false
                return
            }
            
            if let error = error {
                print(error)
            }
        }
    }
    
    @objc func viewButtonWasPressed() {
        let livePhotoViewController = LivePhotoViewController()
        livePhotoViewController.phLivePhoto = livePhoto?.phLivePhoto
        self.present(livePhotoViewController, animated: true) {
            self.saveButton.isHidden = false
        }
    }
    
    @objc func saveButtonWasPressed() {
        self.saveButton.isUserInteractionEnabled = false
        
        livePhoto?.writeToPhotoLibrary(completion: { (livePhoto: LPLivePhoto, error: Error?) in
            DispatchQueue.main.sync {
                
                if let error = error {
                    print(error)
                } else {
                    self.saveButton.setTitle("Saved", for: .normal)
                    self.saveButton.setTitleColor(UIColor.green, for: .normal)
                }
            }
        })
    }
    
}

