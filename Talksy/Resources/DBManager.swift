import Foundation
import FirebaseDatabase

final class DBManager {
    static let shared = DBManager()
    
    private let db = Database.database().reference()

}
 
// MARK: - Account Management

extension DBManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        db.child(email).observeSingleEvent(of: .value) { dataSnapshot in
            guard dataSnapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Inserts new  user to database
    public func insertUser(with user: ChatAppUser) {
        db.child(user.email).setValue(["first_name": user.firstName,
                                       "last_ame": user.lastName])
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let email: String
    //let profilePicUrl: String
}
