import UIKit
import PhotosUI
import LPLivePhotoGenerator

class LivePhotoViewController: UIViewController, PHLivePhotoViewDelegate {
    
    var backButton: UIButton!
    var livePhotoPreviewView: PHLivePhotoView!
    var phLivePhoto: PHLivePhoto! = PHLivePhoto()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.yellow
        
        backButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        backButton.backgroundColor = UIColor.black
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(UIColor.yellow, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonWasPressed), for: .touchUpInside)
        
        livePhotoPreviewView = PHLivePhotoView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        backButton.frame.origin.y = livePhotoPreviewView.frame.maxY - 100
        livePhotoPreviewView.livePhoto = phLivePhoto
        
        view.addSubview(livePhotoPreviewView)
        view.addSubview(backButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        livePhotoPreviewView.startPlayback(with: .full)
    }
    
    @objc func backButtonWasPressed() {
        dismiss(animated: true, completion: nil)
    }
    
}
