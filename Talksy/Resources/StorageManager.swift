import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    private init() {}
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void

    /// Profil fotoğrafını Firebase Storage'a yükler ve indirilebilir URL'yi döndürür.
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        let reference = storage.child("images/\(fileName)")
        
        reference.putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Failed to upload data to Firebase: \(error!.localizedDescription)")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            reference.downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// Profil fotoğrafını Firebase'den getirir.
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path) 
        
        reference.downloadURL { url, error in
            if let error = error {
                print("Failed to fetch download URL: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let url = url {
                completion(.success(url))
            }
        }
    }

    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
    
}
