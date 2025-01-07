import UIKit
import Firebase
import FacebookCore
import GoogleSignIn
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase configuration
        FirebaseApp.configure()

        // Facebook configuration
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle URL for Facebook Sign-In
        let handledByFacebook = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        // Handle URL for Google Sign-In
        let handledByGoogle = GIDSignIn.sharedInstance.handle(url)

        return handledByFacebook || handledByGoogle
    }

    func signInWithGoogle(user: GIDGoogleUser) {
        let idToken = user.idToken?.tokenString
        let accessToken = user.accessToken.tokenString
        
        guard let idToken = idToken else {
            print("Google Authentication failed")
            return
        }
        
        guard let profile = user.profile else {
            print("User profile is nil")
            return
        }

        let email = profile.email
        let firstName = profile.givenName ?? "First Name Not Available"
        let lastName = profile.familyName ?? "Last Name Not Available"

        DBManager.shared.userExists(with: email) { exists in
            if !exists {
                DBManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                              lastName: lastName,
                                                              emailAddress: email))
            }
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Failed to sign in with Firebase: \(error.localizedDescription)")
                return
            }

            print("Successfully signed in with Firebase. User: \(authResult?.user.displayName ?? "No Name")")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!){
        print("Google user was disconnected")
    }
}
