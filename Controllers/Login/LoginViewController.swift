import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn
import Firebase

class LoginViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 10
        field.layer.borderColor = UIColor.black.cgColor
        field.layer.borderWidth = 3.0
        field.placeholder = "Email..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 10
        field.layer.borderColor = UIColor.black.cgColor
        field.layer.borderWidth = 3.0
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1)
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    
    private let googleLogInButton = GIDSignInButton()
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: {[weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        if let clientID = FirebaseApp.app()?.options.clientID {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
        }
        
        
        
        title = "Login"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(register))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        
        imageView.frame = CGRect(
            x: (scrollView.width - size) / 2,
            y: 20,
            width: size,
            height: size)
        
        let spacing: CGFloat = 20
        
        emailField.frame = CGRect(
            x: 30,
            y: imageView.frame.maxY + spacing,
            width: scrollView.width - 60,
            height: 52)
        
        passwordField.frame = CGRect(
            x: 30,
            y: emailField.frame.maxY + spacing,
            width: scrollView.width - 60,
            height: 52)
        
        loginButton.frame = CGRect(
            x: 30,
            y: passwordField.frame.maxY + spacing,
            width: scrollView.width - 60,
            height: 52)
        
        let buttonWidth = scrollView.width - 125
        let buttonHeight: CGFloat = 40
        
        facebookLoginButton.frame = CGRect(
            x: (scrollView.width - buttonWidth) / 2,
            y: loginButton.frame.maxY + spacing,
            width: buttonWidth,
            height: buttonHeight)
        
        googleLogInButton.frame = CGRect(
            x: (scrollView.width - buttonWidth) / 2,
            y: facebookLoginButton.frame.maxY + spacing,
            width: buttonWidth,
            height: buttonHeight)
    }
    
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertLoginError()
            return
        }
        
        // Firebase entegrasyonu buraya eklenebilir.
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func alertLoginError() {
        let alert = UIAlertController(title: "Woops!",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func register() {
        
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (any Error)?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with Facebook!")
            return
        }
        
        let facebookRequest = FacebookLogin.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { connection, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make Facebook graph request!")
                return
            }
            
            guard let username = result["name"] as? String, let email = result["email"] as? String else {
                print("Failed to get mail and name from Facebook result!")
                return
            }
            
            let components = username.components(separatedBy: " ")
            guard components.count == 2 else {
                return
            }
            
            let firstName = components[0]
            let lastName = components[1]
            
            DBManager.shared.userExists(with: email) { exists in
                if !exists {
                    DBManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                  lastName: lastName,
                                                                  emailAddress: email))
                }
            }
            
            let credentials = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credentials) { [weak self] authResult, error in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credentials login failed, MFA may be required! - \(error)")
                    }
                    return
                }
                print("Successfully logged user in!")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }
}
