import Foundation
import FirebaseDatabase

final class DBManager {
    static let shared = DBManager()
    
    private let db = Database.database().reference()

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
    public func insertUser(with user: ChatAppUser) {
        db.child(user.safeEmail).setValue(["first_name": user.firstName,
                                       "last_name": user.lastName])
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
    //let profilePicUrl: String
}
