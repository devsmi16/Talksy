import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    
    public var sender: any MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}

extension MessageKind{
    var messageKindString : String {
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
            case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .custom(_):
            return "custom"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        }
    }
}

struct Sender : SenderType {
    
    public var photoURL : String
    public var senderId: String
    public var displayName: String
    
}


class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        
        return formatter
    }()
    
    public let otherUserEmail: String
    public let conversationId: String
    public var isNewConversation = false
    
    private var messages = [Message]()
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.string(forKey: "email") else { return nil }
        
        let safeEmail = DBManager.safeEmail(email) 
        
        return Sender(photoURL: "",
               senderId: email,
               displayName: "Chat")
    }()
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id ?? UUID().uuidString
        super.init(nibName: nil, bundle: nil)
        
        listeningForMessages(id: conversationId)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray
       
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    private func listeningForMessages(id: String) {
        DBManager.shared.getAllMessagesForConversation(with: id) { result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self.messages = messages
                
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                }
                
            case .failure(let error):
                print("failed to get messages: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: " ").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageID() else{
            return
        }
        print("send:\(text)")
        // send message
        if isNewConversation{
            // create conv in db
            let message = Message(sender: selfSender,
                                  messageId: messageID,
                                  sentDate: Date(),
                                  kind: .text(text))
            
            DBManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User",
                                                   firstMessage: message,
                                                   completion: {success in
                if success {
                    print("message sent")
                }else{
                    print("failed")
                }
            })
        }else {
            // append to existing conv data
        }
    }
    
    private func createMessageID() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") else{
            return nil
        }
        
        let dateString = Self.dateFormatter.string(from:Date())
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print("created new message id: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: any MessageKit.SenderType {
        guard selfSender != nil else {
            fatalError("self sender is nil, email should not be cached")
        }
        return Sender(photoURL: "", senderId: "16", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }

}
