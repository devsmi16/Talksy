import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    private init() {}
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    /// upload picture to firebase storage and returns completion with URL string to download
    
    
    public func uploadProfilePic (with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("image\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            let reference = self.storage.child("image\(fileName)").downloadURL { url, error in
                guard let url = url else {
                        // failed
                        print("failed to get download url")
                        completion(.failure(StorageErrors.failedToGetDownloadURL))
                        return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        })
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
