import Foundation
import FirebaseDatabase

final class DBManager {
    static let shared = DBManager()
    
    private let db = Database.database().reference()

    static func safeEmail(_ email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
 
// MARK: - Account Management

extension DBManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        db.child(safeEmail).observeSingleEvent(of: .value) { dataSnapshot in
            guard dataSnapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Inserts new  user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void) {
        db.child(user.safeEmail).setValue(["first_name": user.firstName,
                                           "last_name": user.lastName],
                                          withCompletionBlock: {error , _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            self.db.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    let newUser = ["name": user.firstName + " " + user.lastName,
                                   "email": user.safeEmail]
                    
                    usersCollection.append(newUser)
                    
                    self.db.child("users").setValue(usersCollection) { error, _ in
                        if let error = error {
                            print("Error updating users: \(error.localizedDescription)")
                        } else {
                            print("User added successfully.")
                        }
                    }
                } else {
                    let newCollection: [[String: String]] = [["name": user.firstName + " " + user.lastName,
                                                              "email": user.safeEmail]]
                    
                    self.db.child("users").setValue(newCollection) { error, _ in
                        if let error = error {
                            print("Error creating users array: \(error.localizedDescription)")
                        } else {
                            print("User collection created successfully.")
                        }
                    }
                }
            }
            completion(true)
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        db.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(dataBaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum dataBaseError: Error {
        case failedToFetch
    }
    
}


// MARK: - sending messages / conv

extension DBManager{
    /// create a new conv with target user email and first message sent
    public func createNewConversation(with user: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        func startNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
            
            let safeEmail = DBManager.safeEmail(currentEmail)
            let ref = db.child("\(safeEmail)")
            
            ref.observeSingleEvent(of: .value) {[weak self] snapshot in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false)
                    print("User not found")
                    return
                }
                
                let messageDate = firstMessage.sentDate
                let sentString = ChatViewController.dateFormatter.string(from: messageDate)
                var message = ""
                
                switch firstMessage.kind {
                case .text(let messageText):
                    message = messageText
                default:
                    message = "[Unsupported message type]"
                }
                
                let conversationID = "conversation_\(firstMessage.messageId)"
                let recipient_newConversationData: [String: Any] = [
                    "id": conversationID,
                    "other_user_email": safeEmail,
                    "name": "me",
                    "latest_message": ["date": sentString, "message": message, "is_read": false]]
                
                // update recipient conv entry
                self?.db.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                    if var conversations = snapshot.value as? [[String: Any]] {
                        // append
                        conversations.append(recipient_newConversationData)
                        self?.db.child("\(otherUserEmail)/conversations").setValue(conversationID)
                    } else {
                        // create
                        self?.db.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                    }
                }
                
                // update current user conv entry
                if var conversations = userNode["conversations"] as? [[String: Any]] {
                    // conv array exists for current user
                    // u should append
                    conversations.append(recipient_newConversationData)
                    userNode["conversations"] = conversations
                    
                    ref.child("conversations").setValue(userNode["conversations"]) { [weak self] error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    }
                    
                } else {
                    // conv array doesnt exist
                    // create it
                    userNode["conversations"] = [recipient_newConversationData]
                }
                
                ref.child("conversations").setValue(userNode["conversations"]) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    public func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: firstMessage.sentDate)
        
        
        let messageContent: String
        switch firstMessage.kind {
        case .text(let text):
            messageContent = text
        default:
            messageContent = "[Unsupported message type]"
        }
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messageContent,
            "date": dateString,
            "sender": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = ["messages": [collectionMessage]]
        
        db.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// fetches and returns all conv for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        db.child("\(email)/conversations").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else {
                    completion(.failure(dataBaseError.failedToFetch))
                    return
                }
                
                let conversations: [Conversation] = value.compactMap {(dictionary) -> Conversation? in
                    guard let conversationId = dictionary["id"] as? String,
                          let name = dictionary["name"] as? String,
                          let otherUserEmail = dictionary["other_user_email"] as? String,
                          let lastMessage = dictionary["latest_message"] as? [String: Any],
                          let date = lastMessage["date"] as? String,
                          let message = lastMessage["message"] as? String,
                          let isRead = lastMessage["is_read"] as? Bool else { return nil }
                    
                    let latestMessageObject = LatestMessage(date: date,
                                                            text: message,
                                                            isRead: isRead)
                    
                    return Conversation(id: conversationId,
                                        name: name,
                                        otherUserEmail: otherUserEmail,
                                        latestMessage: latestMessageObject)
                }
                
                completion(.success(conversations))
            })
        }
    
    /// gets all messages for a given conv
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void){
        db.child("\(id)/messages").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else {
                    completion(.failure(dataBaseError.failedToFetch))
                    return
                }
                
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else{ return nil }
                
                let sender = Sender(photoURL: " ",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            })
                
                completion(.success(messages))
            })
    }
    
    /// sends a message with target conv and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String{
        //gnd-tester-com_profile_picture.png
         
        return "\(safeEmail)_profile_picture.png"
    }
}
