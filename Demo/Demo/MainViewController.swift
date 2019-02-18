import UIKit
import PhotosUI

class MainViewController: UIViewController {
    
    var createButton: UIButton!
    var createActivityIndicatorView: UIActivityIndicatorView!
    var viewButton: UIButton!
    var saveButton: UIButton!
    var deleteButton: UIButton!
    
    var imagePath: String!
    var videoPath: String!
    var livePhoto: LivePhoto?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePath = Bundle.main.path(forResource: "image", ofType: "JPEG")
        videoPath = Bundle.main.path(forResource: "video", ofType: "MOV")
        
        view.backgroundColor = UIColor.black
        
        let height = view.frame.height / 5
        let width = view.frame.width * 0.8
        let spaceBetween = height / 5
        
        createButton = UIButton(frame: CGRect(x: 0, y: spaceBetween, width: width, height: height))
        createButton.center.x = view.center.x
        createButton.backgroundColor = UIColor.black
        createButton.setTitle("Create Live Photo", for: .normal)
        createButton.layer.cornerRadius = 10
        createButton.layer.borderWidth = 1
        createButton.layer.borderColor = UIColor.yellow.cgColor
        createButton.addTarget(self, action: #selector(createButtonWasPressed), for: .touchUpInside)
        
        viewButton = UIButton(frame: CGRect(x: 0, y: createButton.frame.maxY + spaceBetween, width: width, height: height))
        viewButton.center.x = view.center.x
        viewButton.backgroundColor = UIColor.black
        viewButton.setTitle("View Live Photo", for: .normal)
        viewButton.layer.cornerRadius = 10
        viewButton.layer.borderWidth = 1
        viewButton.layer.borderColor = UIColor.yellow.cgColor
        viewButton.addTarget(self, action: #selector(viewButtonWasPressed), for: .touchUpInside)
        viewButton.isHidden = true
        
        createActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        createActivityIndicatorView.center = viewButton.center
        
        saveButton = UIButton(frame: CGRect(x: 0, y: viewButton.frame.maxY + spaceBetween, width: width, height: height))
        saveButton.center.x = view.center.x
        saveButton.backgroundColor = UIColor.black
        saveButton.setTitle("Save Live Photo", for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = UIColor.yellow.cgColor
        saveButton.addTarget(self, action: #selector(saveButtonWasPressed), for: .touchUpInside)
        saveButton.isHidden = true
        
        deleteButton = UIButton(frame: CGRect(x: 0, y: saveButton.frame.maxY + spaceBetween, width: width, height: height))
        deleteButton.center.x = view.center.x
        deleteButton.backgroundColor = UIColor.black
        deleteButton.setTitle("Delete From Temp Directory", for: .normal)
        deleteButton.layer.cornerRadius = 10
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.yellow.cgColor
        deleteButton.addTarget(self, action: #selector(deleteButtonWasPressed), for: .touchUpInside)
        deleteButton.isHidden = true
        
        view.addSubview(createButton)
        view.addSubview(createActivityIndicatorView)
        view.addSubview(viewButton)
        view.addSubview(saveButton)
        view.addSubview(deleteButton)
    }

    @objc func createButtonWasPressed() {
        
        self.viewButton.isHidden = true
        self.saveButton.isHidden = true
        self.deleteButton.isHidden = true
        
        createActivityIndicatorView.startAnimating()
        
        LivePhotoGenerator(imagePath: self.imagePath, videoPath: self.videoPath).create { (livePhoto: LivePhoto?, error: Error?) in
            if let livePhoto = livePhoto {
                self.livePhoto = livePhoto
                self.createActivityIndicatorView.stopAnimating()
                self.viewButton.isHidden = false
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
        
        livePhoto?.writeToPhotoLibrary(completion: { (success: Bool, error: Error?) in
            DispatchQueue.main.sync {
                if success {
                    self.saveButton.setTitle("Saved", for: .normal)
                    self.saveButton.setTitleColor(UIColor.green, for: .normal)
                    self.deleteButton.isHidden = false
                }
            }
        })
    }
    
    @objc func deleteButtonWasPressed() {
        self.deleteButton.isUserInteractionEnabled = false
        
        livePhoto?.removeFilesFromTempDirectory(completion: { (success: Bool, error: Error?) in
            if success {
                self.deleteButton.setTitle("Deleted", for: .normal)
                self.deleteButton.setTitleColor(UIColor.red, for: .normal)
            }
        })
    }
}

