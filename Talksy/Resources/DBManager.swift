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
