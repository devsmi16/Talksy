import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {

    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 10
        let imageSize: CGFloat = 100
        let labelWidth = contentView.width - imageSize - (3 * padding)
        let labelHeight = (contentView.height - (3 * padding)) / 2
        
        userImageView.frame = CGRect(x: padding, y: padding, width: imageSize, height: imageSize)
        
        userNameLabel.frame = CGRect(x: userImageView.frame.maxX + padding,
                                     y: padding,
                                     width: labelWidth,
                                     height: labelHeight)
        
        userMessageLabel.frame = CGRect(x: userImageView.frame.maxX + padding,
                                        y: userNameLabel.frame.maxY + padding,
                                        width: labelWidth,
                                        height: labelHeight)
    }
    
    public func configure(with model: Conversation) {
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name
        
        let path = "\(model.otherUserEmail)_profile_picture.png"
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
                
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
        
    }
    
}
