import UIKit

class ActionButton: UIButton {
    
    init(frame: CGRect, title: String, hidden: Bool) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
        self.setTitle(title, for: .normal)
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.yellow.cgColor
        self.isHidden = hidden
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
